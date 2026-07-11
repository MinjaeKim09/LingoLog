"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const { validateStoryRequest, validateStoryResponse } = require("../story");

const validRequest = {
  subscriptionJWS: "signed-transaction",
  languageCode: "ko",
  languageName: "Korean",
  words: [
    { word: "안녕", translation: "hello" },
    { word: "친구", translation: "friend" },
    { word: "학교", translation: "school" },
  ],
};

test("validates and bounds a story generation request", () => {
  const request = validateStoryRequest(validRequest);
  assert.equal(request.words.length, 3);
  assert.equal(request.languageCode, "ko");
  assert.throws(() => validateStoryRequest({ ...validRequest, languageCode: "not a code" }));
  assert.throws(() => validateStoryRequest({ ...validRequest, words: validRequest.words.slice(0, 2) }));
});

test("accepts only complete, safe story responses", () => {
  const response = {
    title: "A day at school",
    story: "A short story.",
    questions: Array.from({ length: 4 }, (_, correctIndex) => ({
      question: "Question?",
      options: ["A", "B", "C", "D"],
      correctIndex,
    })),
  };
  assert.equal(validateStoryResponse(response).questions.length, 4);
  assert.throws(() => validateStoryResponse({ ...response, questions: response.questions.slice(0, 3) }));
  assert.throws(() => validateStoryResponse({ ...response, questions: [{ question: "Bad", options: [], correctIndex: 0 }] }));
});
