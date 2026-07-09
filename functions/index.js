"use strict";

const { createHash } = require("node:crypto");
const admin = require("firebase-admin");
const { getAppCheck } = require("firebase-admin/app-check");
const { FieldValue } = require("firebase-admin/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret, defineString } = require("firebase-functions/params");
const {
  Environment,
  SignedDataVerifier,
} = require("@apple/app-store-server-library");
const {
  clientError: translationClientError,
  fetchSupportedLanguages,
  translateWithGoogle,
  validateTranslationRequest,
} = require("./translation");

admin.initializeApp();

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
const APPLE_ROOT_CERT_BASE64 = defineSecret("APPLE_ROOT_CERT_BASE64");
const GOOGLE_TRANSLATE_API_KEY = defineSecret("GOOGLE_TRANSLATE_API_KEY");
const BUNDLE_ID = defineString("BUNDLE_ID", { default: "mkim.LingoLog" });
const TRANSLATION_APP_ID = defineString("TRANSLATION_APP_ID");
const APPLE_APP_ID = defineString("APPLE_APP_ID", { default: "" });
const APP_STORE_ENVIRONMENT = defineString("APP_STORE_ENVIRONMENT", {
  default: "Sandbox",
});
const DEV_SKIP_APPLE_VERIFICATION = defineString("DEV_SKIP_APPLE_VERIFICATION", {
  default: "false",
});

const DAILY_STORIES_PRODUCT_ID = "com.lingolog.dailystories.monthly";
const GEMINI_MODEL_URL =
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent";
const TRANSLATION_RATE_LIMIT = 60;
const TRANSLATION_RATE_WINDOW_MS = 60 * 1000;
const LANGUAGE_CACHE_TTL_MS = 24 * 60 * 60 * 1000;
let cachedGoogleLanguages = null;
let cachedGoogleLanguagesExpiresAt = 0;

exports.generateDailyStory = onRequest(
  {
    cors: true,
    secrets: [GEMINI_API_KEY, APPLE_ROOT_CERT_BASE64],
    timeoutSeconds: 60,
    memory: "512MiB",
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "Use POST to generate a story." });
      return;
    }

    let quotaRef = null;
    try {
      const payload = validateRequest(req.body);
      const transaction = await verifySubscription(payload.subscriptionJWS);
      quotaRef = await reserveDailyQuota(transaction.originalTransactionId);

      const story = await generateStoryWithGemini(payload);
      await quotaRef.update({
        completedAt: FieldValue.serverTimestamp(),
      });
      res.status(200).json(story);
    } catch (error) {
      if (quotaRef && (!error.statusCode || error.statusCode >= 500)) {
        await quotaRef.delete().catch((deleteError) => console.error(deleteError));
      }

      const status = error.statusCode || 500;
      const message =
        status >= 500 ? "Story generation failed. Please try again later." : error.message;
      console.error(error);
      res.status(status).json({ error: message });
    }
  }
);

exports.translation = onRequest(
  {
    cors: true,
    secrets: [GOOGLE_TRANSLATE_API_KEY],
    timeoutSeconds: 20,
    memory: "256MiB",
  },
  async (req, res) => {
    try {
      if (req.method !== "GET" && req.method !== "POST") {
        res.status(405).json({ error: "Use GET for languages or POST for translation." });
        return;
      }

      const appId = await verifiedTranslationAppId(req);
      await reserveTranslationRateLimit(appId);

      if (req.method === "GET") {
        res.status(200).json({ languages: await supportedGoogleLanguages() });
        return;
      }

      const payload = validateTranslationRequest(req.body);
      const supportedLanguages = await supportedGoogleLanguages();
      const supportedCodes = new Map(
        supportedLanguages.map((language) => [language.code.toLowerCase(), language.code])
      );
      const sourceLanguage = supportedCodes.get(payload.sourceLanguage.toLowerCase());
      const targetLanguage = supportedCodes.get(payload.targetLanguage.toLowerCase());
      if (!sourceLanguage || !targetLanguage) {
        throw translationClientError("The selected language is not supported.");
      }

      if (sourceLanguage === targetLanguage) {
        res.status(200).json({ translatedText: payload.text });
        return;
      }

      const translatedText = await translateWithGoogle(GOOGLE_TRANSLATE_API_KEY.value(), {
        ...payload,
        sourceLanguage,
        targetLanguage,
      });
      res.status(200).json({ translatedText });
    } catch (error) {
      const status = error.statusCode || 500;
      if (status >= 500) {
        console.error("Translation request failed.", error);
      }
      res.status(status).json({ error: translationErrorMessage(error) });
    }
  }
);

async function verifiedTranslationAppId(req) {
  const token = stringValue(req.get("X-Firebase-AppCheck"));
  if (!token) {
    throw translationClientError("A valid app attestation is required.", 401);
  }

  try {
    const decodedToken = await getAppCheck().verifyToken(token);
    if (decodedToken.appId !== TRANSLATION_APP_ID.value()) {
      throw translationClientError("A valid app attestation is required.", 401);
    }
    return decodedToken.appId;
  } catch (error) {
    if (error.statusCode) {
      throw error;
    }
    throw translationClientError("A valid app attestation is required.", 401);
  }
}

async function reserveTranslationRateLimit(appId) {
  const appHash = createHash("sha256").update(appId).digest("hex");
  const rateLimitRef = admin.firestore().collection("translationRateLimits").doc(appHash);
  const now = Date.now();

  await admin.firestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(rateLimitRef);
    const current = snapshot.exists ? snapshot.data() : null;
    const windowStartedAt = Number(current && current.windowStartedAt) || now;
    const isCurrentWindow = now - windowStartedAt < TRANSLATION_RATE_WINDOW_MS;
    const count = isCurrentWindow ? Number(current && current.count) || 0 : 0;

    if (count >= TRANSLATION_RATE_LIMIT) {
      throw translationClientError("Too many translation requests. Please try again shortly.", 429);
    }

    transaction.set(
      rateLimitRef,
      {
        count: count + 1,
        windowStartedAt: isCurrentWindow ? windowStartedAt : now,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  });
}

async function supportedGoogleLanguages() {
  if (cachedGoogleLanguages && Date.now() < cachedGoogleLanguagesExpiresAt) {
    return cachedGoogleLanguages;
  }

  const languages = await fetchSupportedLanguages(GOOGLE_TRANSLATE_API_KEY.value());
  cachedGoogleLanguages = languages;
  cachedGoogleLanguagesExpiresAt = Date.now() + LANGUAGE_CACHE_TTL_MS;
  return languages;
}

function translationErrorMessage(error) {
  if (error.statusCode && error.statusCode < 500) {
    return error.message;
  }
  return "Translation is temporarily unavailable. Please try again later.";
}

function validateRequest(body) {
  const subscriptionJWS = stringValue(body.subscriptionJWS);
  const languageCode = stringValue(body.languageCode);
  const languageName = stringValue(body.languageName);
  const words = Array.isArray(body.words) ? body.words : [];

  if (!subscriptionJWS || !languageCode || !languageName) {
    throw clientError("Missing subscription or language information.");
  }

  const cleanedWords = words
    .map((entry) => ({
      word: stringValue(entry.word),
      translation: stringValue(entry.translation),
    }))
    .filter((entry) => entry.word && entry.translation)
    .slice(0, 8);

  if (cleanedWords.length < 3) {
    throw clientError("At least 3 vocabulary words are required.");
  }

  return {
    subscriptionJWS,
    languageCode,
    languageName,
    words: cleanedWords,
  };
}

async function verifySubscription(subscriptionJWS) {
  if (DEV_SKIP_APPLE_VERIFICATION.value() === "true") {
    return {
      originalTransactionId: `dev-${hashString(subscriptionJWS)}`,
      productId: DAILY_STORIES_PRODUCT_ID,
    };
  }

  const environment =
    APP_STORE_ENVIRONMENT.value() === "Production"
      ? Environment.PRODUCTION
      : Environment.SANDBOX;
  const appAppleId = APPLE_APP_ID.value() ? Number(APPLE_APP_ID.value()) : undefined;
  const rootCert = Buffer.from(APPLE_ROOT_CERT_BASE64.value(), "base64");
  const verifier = new SignedDataVerifier(
    [rootCert],
    true,
    environment,
    BUNDLE_ID.value(),
    appAppleId
  );

  const transaction = await verifier.verifyAndDecodeTransaction(subscriptionJWS);
  const expiresDate = Number(transaction.expiresDate || 0);

  if (transaction.productId !== DAILY_STORIES_PRODUCT_ID) {
    throw clientError("Daily Stories subscription is not active.");
  }

  if (transaction.revocationDate || !expiresDate || expiresDate <= Date.now()) {
    throw clientError("Daily Stories subscription is not active.");
  }

  if (!transaction.originalTransactionId) {
    throw clientError("Subscription transaction is missing required information.");
  }

  return transaction;
}

async function reserveDailyQuota(originalTransactionId) {
  const today = new Date().toISOString().slice(0, 10);
  const quotaID = `${originalTransactionId}_${today}`;
  const quotaRef = admin.firestore().collection("dailyStoryQuota").doc(quotaID);

  await admin.firestore().runTransaction(async (transaction) => {
    const snapshot = await transaction.get(quotaRef);
    if (snapshot.exists) {
      throw clientError("You have already generated today's story.");
    }

    transaction.set(quotaRef, {
      originalTransactionId,
      date: today,
      createdAt: FieldValue.serverTimestamp(),
      status: "pending",
    });
  });
  
  return quotaRef;
}

async function generateStoryWithGemini(payload) {
  const prompt = buildPrompt(payload);
  const response = await fetch(`${GEMINI_MODEL_URL}?key=${GEMINI_API_KEY.value()}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      contents: [
        {
          parts: [{ text: prompt }],
        },
      ],
      generationConfig: {
        temperature: 0.8,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 2048,
        responseMimeType: "application/json",
      },
    }),
  });

  const data = await response.json();
  if (!response.ok) {
    const message = data.error && data.error.message ? data.error.message : "Gemini failed.";
    throw serverError(message);
  }

  const text = data.candidates &&
    data.candidates[0] &&
    data.candidates[0].content &&
    data.candidates[0].content.parts &&
    data.candidates[0].content.parts[0] &&
    data.candidates[0].content.parts[0].text;

  if (!text) {
    throw serverError("Gemini returned an invalid response.");
  }

  try {
    return JSON.parse(stripMarkdownFence(text));
  } catch (error) {
    throw serverError(`Could not parse Gemini story JSON: ${error.message}`);
  }
}

function buildPrompt(payload) {
  const wordList = payload.words
    .map((entry) => `${entry.word} (${entry.translation})`)
    .join(", ");

  return `
You are a creative language learning assistant. Write a short, engaging story for language learners.

TASK: Write a short story (200-300 words) in ${payload.languageName} that naturally incorporates the following vocabulary words. The story should be simple enough for intermediate learners but interesting to read.

VOCABULARY WORDS TO INCLUDE:
${wordList}

REQUIREMENTS:
1. The story should be written entirely in ${payload.languageName}
2. Use all the vocabulary words naturally within the story
3. Keep sentences relatively simple but varied
4. Create an engaging narrative with a clear beginning, middle, and end
5. After the story, create 4 multiple-choice comprehension questions about the story content and vocabulary usage

RESPONSE FORMAT (strict JSON):
{
  "title": "Story title in ${payload.languageName}",
  "story": "The full story text in ${payload.languageName}...",
  "questions": [
    {
      "question": "Question text in ${payload.languageName}?",
      "options": ["Option A", "Option B", "Option C", "Option D"],
      "correctIndex": 0
    }
  ]
}

Make sure correctIndex is 0-based. Return ONLY the JSON object, no additional text.
`.trim();
}

function stripMarkdownFence(text) {
  return text
    .trim()
    .replace(/^```json\s*/i, "")
    .replace(/^```\s*/i, "")
    .replace(/```$/i, "")
    .trim();
}

function stringValue(value) {
  return typeof value === "string" ? value.trim() : "";
}

function hashString(value) {
  let hash = 0;
  for (let index = 0; index < value.length; index += 1) {
    hash = ((hash << 5) - hash + value.charCodeAt(index)) | 0;
  }
  return Math.abs(hash).toString(36);
}

function clientError(message) {
  const error = new Error(message);
  error.statusCode = 400;
  return error;
}

function serverError(message) {
  const error = new Error(message);
  error.statusCode = 500;
  return error;
}
