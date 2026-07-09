"use strict";

const GOOGLE_TRANSLATE_URL =
  "https://translation.googleapis.com/language/translate/v2";
const GOOGLE_LANGUAGES_URL =
  "https://translation.googleapis.com/language/translate/v2/languages";
const MAX_TEXT_CODE_POINTS = 5000;
const LANGUAGE_CODE_PATTERN = /^[A-Za-z]{2,3}(?:-[A-Za-z0-9]{2,8})*$/;

function stringValue(value) {
  return typeof value === "string" ? value.trim() : "";
}

function clientError(message, statusCode = 400) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

function providerError(message) {
  const error = new Error(message);
  error.statusCode = 502;
  return error;
}

function validateTranslationRequest(body) {
  const text = typeof (body && body.text) === "string" ? body.text : "";
  const sourceLanguage = stringValue(body && body.sourceLanguage);
  const targetLanguage = stringValue(body && body.targetLanguage);

  if (!text.trim()) {
    throw clientError("Text is required.");
  }

  if (Array.from(text).length > MAX_TEXT_CODE_POINTS) {
    throw clientError(`Text must be ${MAX_TEXT_CODE_POINTS} characters or fewer.`);
  }

  if (!LANGUAGE_CODE_PATTERN.test(sourceLanguage) || !LANGUAGE_CODE_PATTERN.test(targetLanguage)) {
    throw clientError("A valid source and target language are required.");
  }

  return { text, sourceLanguage, targetLanguage };
}

function mapGoogleLanguages(data) {
  const languages = data && data.data && data.data.languages;
  if (!Array.isArray(languages)) {
    throw providerError("Google Translate returned an invalid language response.");
  }

  const uniqueLanguages = new Map();
  for (const language of languages) {
    const code = stringValue(language && language.language);
    const name = stringValue(language && language.name);
    if (LANGUAGE_CODE_PATTERN.test(code) && name) {
      uniqueLanguages.set(code.toLowerCase(), { code, name });
    }
  }

  const result = Array.from(uniqueLanguages.values()).sort((left, right) =>
    left.name.localeCompare(right.name, "en")
  );
  if (!result.length) {
    throw providerError("Google Translate returned no supported languages.");
  }
  return result;
}

function translationFromGoogleResponse(data) {
  const translatedText =
    data &&
    data.data &&
    data.data.translations &&
    data.data.translations[0] &&
    data.data.translations[0].translatedText;

  if (typeof translatedText !== "string") {
    throw providerError("Google Translate returned an invalid translation response.");
  }
  return translatedText;
}

function googleErrorMessage(data) {
  return data && data.error && typeof data.error.message === "string"
    ? data.error.message
    : "Google Translate request failed.";
}

async function googleJSON(response) {
  try {
    return await response.json();
  } catch {
    throw providerError("Google Translate returned an unreadable response.");
  }
}

async function fetchSupportedLanguages(apiKey) {
  const url = new URL(GOOGLE_LANGUAGES_URL);
  url.searchParams.set("key", apiKey);
  url.searchParams.set("target", "en");
  url.searchParams.set("model", "nmt");

  const response = await fetch(url);
  const data = await googleJSON(response);
  if (!response.ok) {
    throw providerError(googleErrorMessage(data));
  }
  return mapGoogleLanguages(data);
}

async function translateWithGoogle(apiKey, payload) {
  const url = new URL(GOOGLE_TRANSLATE_URL);
  url.searchParams.set("key", apiKey);
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      q: payload.text,
      source: payload.sourceLanguage,
      target: payload.targetLanguage,
      format: "text",
      model: "nmt",
    }),
  });
  const data = await googleJSON(response);
  if (!response.ok) {
    throw providerError(googleErrorMessage(data));
  }
  return translationFromGoogleResponse(data);
}

module.exports = {
  MAX_TEXT_CODE_POINTS,
  clientError,
  fetchSupportedLanguages,
  mapGoogleLanguages,
  translateWithGoogle,
  translationFromGoogleResponse,
  validateTranslationRequest,
};
