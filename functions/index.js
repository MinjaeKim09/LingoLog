"use strict";

const { createHash } = require("node:crypto");
const admin = require("firebase-admin");
const { FieldValue } = require("firebase-admin/firestore");
const { onRequest } = require("firebase-functions/v2/https");
const { defineSecret, defineString } = require("firebase-functions/params");
const { Environment, SignedDataVerifier } = require("@apple/app-store-server-library");
const { requestClientKey, verifyAppAttestation } = require("./app-check");
const { buildPrompt, clientError, serverError, stripMarkdownFence, validateStoryRequest, validateStoryResponse } = require("./story");
const { fetchSupportedLanguages, translateWithGoogle, validateTranslationRequest } = require("./translation");

admin.initializeApp();

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
const APPLE_ROOT_CERT_BASE64 = defineSecret("APPLE_ROOT_CERT_BASE64");
const GOOGLE_TRANSLATE_API_KEY = defineSecret("GOOGLE_TRANSLATE_API_KEY");
const IOS_APP_ID = defineString("IOS_APP_ID");
const BUNDLE_ID = defineString("BUNDLE_ID", { default: "mkim.LingoLog" });
const APPLE_APP_ID = defineString("APPLE_APP_ID", { default: "" });
const APP_STORE_ENVIRONMENT = defineString("APP_STORE_ENVIRONMENT", { default: "Sandbox" });
const DEV_SKIP_APPLE_VERIFICATION = defineString("DEV_SKIP_APPLE_VERIFICATION", { default: "false" });

const DAILY_STORIES_PRODUCT_ID = "com.lingolog.dailystories.monthly";
const GEMINI_MODEL_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-3-flash-preview:generateContent";
const TRANSLATION_RATE_LIMIT = 60;
const TRANSLATION_RATE_WINDOW_MS = 60 * 1000;
const LANGUAGE_CACHE_TTL_MS = 24 * 60 * 60 * 1000;
let cachedGoogleLanguages = null;
let cachedGoogleLanguagesExpiresAt = 0;

exports.generateDailyStory = onRequest({ cors: false, secrets: [GEMINI_API_KEY, APPLE_ROOT_CERT_BASE64], timeoutSeconds: 60, memory: "512MiB" }, async (req, res) => {
  if (req.method !== "POST") {
    res.status(405).json({ error: "Use POST to generate a story." });
    return;
  }
  let quotaRef = null;
  try {
    await verifyAppAttestation(req, IOS_APP_ID.value());
    const payload = validateStoryRequest(req.body);
    const transaction = await verifySubscription(payload.subscriptionJWS);
    quotaRef = await reserveDailyQuota(transaction.originalTransactionId);
    const story = await generateStoryWithGemini(payload);
    await quotaRef.update({ completedAt: FieldValue.serverTimestamp(), status: "completed" });
    res.status(200).json(story);
  } catch (error) {
    if (quotaRef && (!error.statusCode || error.statusCode >= 500)) {
      await quotaRef.delete().catch((deleteError) => console.error("Failed to release story quota", deleteError));
    }
    console.error("Daily story request failed", error);
    res.status(error.statusCode || 500).json({ error: error.statusCode && error.statusCode < 500 ? error.message : "Story generation failed. Please try again later." });
  }
});

exports.translation = onRequest({ cors: false, secrets: [GOOGLE_TRANSLATE_API_KEY], timeoutSeconds: 20, memory: "256MiB" }, async (req, res) => {
  try {
    if (req.method !== "GET" && req.method !== "POST") {
      res.status(405).json({ error: "Use GET for languages or POST for translation." });
      return;
    }
    const appId = await verifyAppAttestation(req, IOS_APP_ID.value());
    await reserveTranslationRateLimit(appId, requestClientKey(req));
    if (req.method === "GET") {
      res.status(200).json({ languages: await supportedGoogleLanguages() });
      return;
    }
    const payload = validateTranslationRequest(req.body);
    const supportedCodes = new Map((await supportedGoogleLanguages()).map((language) => [language.code.toLowerCase(), language.code]));
    const sourceLanguage = supportedCodes.get(payload.sourceLanguage.toLowerCase());
    const targetLanguage = supportedCodes.get(payload.targetLanguage.toLowerCase());
    if (!sourceLanguage || !targetLanguage) throw clientError("The selected language is not supported.");
    if (sourceLanguage === targetLanguage) {
      res.status(200).json({ translatedText: payload.text });
      return;
    }
    res.status(200).json({ translatedText: await translateWithGoogle(GOOGLE_TRANSLATE_API_KEY.value(), { ...payload, sourceLanguage, targetLanguage }) });
  } catch (error) {
    if (!error.statusCode || error.statusCode >= 500) console.error("Translation request failed", error);
    res.status(error.statusCode || 500).json({ error: error.statusCode && error.statusCode < 500 ? error.message : "Translation is temporarily unavailable. Please try again later." });
  }
});

async function reserveTranslationRateLimit(appId, clientKey) {
  const id = createHash("sha256").update(`${appId}:${clientKey}`).digest("hex");
  const ref = admin.firestore().collection("translationRateLimits").doc(id);
  const now = Date.now();
  await admin.firestore().runTransaction(async (transaction) => {
    const current = (await transaction.get(ref)).data();
    const startedAt = Number(current && current.windowStartedAt) || now;
    const currentWindow = now - startedAt < TRANSLATION_RATE_WINDOW_MS;
    const count = currentWindow ? Number(current && current.count) || 0 : 0;
    if (count >= TRANSLATION_RATE_LIMIT) throw clientError("Too many translation requests. Please try again shortly.", 429);
    transaction.set(ref, { count: count + 1, windowStartedAt: currentWindow ? startedAt : now, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
  });
}

async function supportedGoogleLanguages() {
  if (cachedGoogleLanguages && Date.now() < cachedGoogleLanguagesExpiresAt) return cachedGoogleLanguages;
  cachedGoogleLanguages = await fetchSupportedLanguages(GOOGLE_TRANSLATE_API_KEY.value());
  cachedGoogleLanguagesExpiresAt = Date.now() + LANGUAGE_CACHE_TTL_MS;
  return cachedGoogleLanguages;
}

async function verifySubscription(subscriptionJWS) {
  if (DEV_SKIP_APPLE_VERIFICATION.value() === "true") return { originalTransactionId: `dev-${createHash("sha256").update(subscriptionJWS).digest("hex")}`, productId: DAILY_STORIES_PRODUCT_ID };
  const environment = APP_STORE_ENVIRONMENT.value() === "Production" ? Environment.PRODUCTION : Environment.SANDBOX;
  const appAppleId = APPLE_APP_ID.value() ? Number(APPLE_APP_ID.value()) : undefined;
  const rootCert = Buffer.from(APPLE_ROOT_CERT_BASE64.value(), "base64");
  const transaction = await new SignedDataVerifier([rootCert], true, environment, BUNDLE_ID.value(), appAppleId).verifyAndDecodeTransaction(subscriptionJWS);
  if (transaction.productId !== DAILY_STORIES_PRODUCT_ID || transaction.revocationDate || !transaction.expiresDate || Number(transaction.expiresDate) <= Date.now() || !transaction.originalTransactionId) {
    throw clientError("Daily Stories subscription is not active.");
  }
  return transaction;
}

async function reserveDailyQuota(originalTransactionId) {
  const date = new Date().toISOString().slice(0, 10);
  const ref = admin.firestore().collection("dailyStoryQuota").doc(`${originalTransactionId}_${date}`);
  await admin.firestore().runTransaction(async (transaction) => {
    if ((await transaction.get(ref)).exists) throw clientError("You have already generated today's story.");
    transaction.set(ref, { originalTransactionId, date, createdAt: FieldValue.serverTimestamp(), status: "pending" });
  });
  return ref;
}

async function generateStoryWithGemini(payload) {
  const response = await fetch(`${GEMINI_MODEL_URL}?key=${GEMINI_API_KEY.value()}`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ contents: [{ parts: [{ text: buildPrompt(payload) }] }], generationConfig: { temperature: 0.8, topK: 40, topP: 0.95, maxOutputTokens: 2048, responseMimeType: "application/json" } }) });
  const data = await response.json().catch(() => null);
  if (!response.ok) throw serverError(data && data.error && data.error.message ? data.error.message : "Gemini failed.");
  const text = data && data.candidates && data.candidates[0] && data.candidates[0].content && data.candidates[0].content.parts && data.candidates[0].content.parts[0] && data.candidates[0].content.parts[0].text;
  if (!text) throw serverError("Gemini returned an invalid response.");
  try {
    return validateStoryResponse(JSON.parse(stripMarkdownFence(text)));
  } catch (error) {
    if (error.statusCode) throw error;
    throw serverError("Could not parse the story response.");
  }
}
