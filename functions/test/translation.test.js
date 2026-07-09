"use strict";

const test = require("node:test");
const assert = require("node:assert/strict");
const {
  MAX_TEXT_CODE_POINTS,
  mapGoogleLanguages,
  translationFromGoogleResponse,
  validateTranslationRequest,
} = require("../translation");

test("validates a plain-text translation request", () => {
  assert.deepEqual(
    validateTranslationRequest({
      text: "  hello  ",
      sourceLanguage: "en",
      targetLanguage: "ko",
    }),
    { text: "  hello  ", sourceLanguage: "en", targetLanguage: "ko" }
  );
});

test("rejects empty, oversized, and malformed translation requests", () => {
  assert.throws(() => validateTranslationRequest({ text: "", sourceLanguage: "en", targetLanguage: "ko" }));
  assert.throws(() =>
    validateTranslationRequest({
      text: "a".repeat(MAX_TEXT_CODE_POINTS + 1),
      sourceLanguage: "en",
      targetLanguage: "ko",
    })
  );
  assert.throws(() =>
    validateTranslationRequest({ text: "hello", sourceLanguage: "english", targetLanguage: "ko" })
  );
});

test("maps, de-duplicates, and sorts Google language records", () => {
  assert.deepEqual(
    mapGoogleLanguages({
      data: {
        languages: [
          { language: "ko", name: "Korean" },
          { language: "en", name: "English" },
          { language: "EN", name: "English duplicate" },
        ],
      },
    }),
    [
      { code: "EN", name: "English duplicate" },
      { code: "ko", name: "Korean" },
    ]
  );
});

test("extracts the translated text from Google responses", () => {
  assert.equal(
    translationFromGoogleResponse({
      data: { translations: [{ translatedText: "hola" }] },
    }),
    "hola"
  );
});
