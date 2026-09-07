"use strict";

const assert = require("node:assert/strict");
const test = require("node:test");
const { getDailyStory, RESERVATION_TTL_MS } = require("../daily-story");

// Serialize transactions and apply writes only after their callback succeeds,
// mirroring the atomicity on which the quota handler relies.
function database() {
  const documents = new Map();
  let queue = Promise.resolve();
  return {
    documents,
    failCompletion: null,
    collection: (collection) => ({ doc: (id) => `${collection}/${id}` }),
    runTransaction(callback) {
      const operation = queue.then(async () => {
        const writes = [];
        let completing = false;
        const value = await callback({
          get: async (ref) => ({ data: () => documents.get(ref) }),
          set: (ref, data) => writes.push(() => documents.set(ref, data)),
          update: (ref, data) => {
            completing = data.status === "completed";
            writes.push(() => documents.set(ref, { ...documents.get(ref), ...data }));
          },
          delete: (ref) => writes.push(() => documents.delete(ref)),
        });
        const failure = completing && this.failCompletion;
        this.failCompletion = completing ? null : this.failCompletion;
        if (failure === "before") throw new Error("Commit failed");
        writes.forEach((write) => write());
        if (failure === "after") throw new Error("Commit response lost");
        return value;
      });
      queue = operation.catch(() => {});
      return operation;
    },
  };
}

function fixture() {
  const db = database();
  let clock = Date.parse("2026-09-05T12:00:00Z");
  let generations = 0;
  const story = { title: "A story", story: "Content", questions: [] };
  const options = {
    db,
    originalTransactionId: "subscriber",
    payload: { languageCode: "ko", words: [{ word: "친구", translation: "friend" }] },
    generateStory: async () => { generations += 1; return story; },
    serverTimestamp: () => new Date(clock),
    now: () => clock,
  };
  return {
    db, options,
    generations: () => generations,
    advance: (milliseconds) => { clock += milliseconds; },
  };
}

test("a lost HTTP response can be recovered with the original story and vocabulary", async () => {
  const f = fixture();
  const first = await getDailyStory(f.options);
  const retry = await getDailyStory({
    ...f.options,
    payload: { ...f.options.payload, words: [{ word: "학교", translation: "school" }] },
  });
  assert.deepEqual(retry, first);
  assert.deepEqual(retry.words, f.options.payload.words);
  assert.equal(f.generations(), 1);
  assert.equal([...f.db.documents.values()][0].status, "completed");
});

test("another language cannot receive or relabel today's cached story", async () => {
  const f = fixture();
  await getDailyStory(f.options);
  await assert.rejects(getDailyStory({
    ...f.options, payload: { ...f.options.payload, languageCode: "ja" },
  }), { statusCode: 409 });
  assert.equal(f.generations(), 1);
});

test("concurrent requests generate only once and can retry after completion", async () => {
  const f = fixture();
  let finish;
  let started;
  const ready = new Promise((resolve) => { started = resolve; });
  const first = getDailyStory({
    ...f.options,
    generateStory: () => new Promise((resolve) => { finish = resolve; started(); }),
  });
  await ready;
  await assert.rejects(getDailyStory(f.options), { statusCode: 409 });
  finish({ title: "Original" });
  const result = await first;
  assert.deepEqual(await getDailyStory(f.options), result);
  assert.equal(f.generations(), 0);
});

test("a provider failure releases the reservation for retry", async () => {
  const f = fixture();
  await assert.rejects(getDailyStory({
    ...f.options, generateStory: async () => { throw new Error("Provider failed"); },
  }), /Provider failed/);
  assert.equal(f.db.documents.size, 0);
  await getDailyStory(f.options);
  assert.equal(f.generations(), 1);
});

test("a failed result commit releases the quota", async () => {
  const f = fixture();
  f.db.failCompletion = "before";
  await assert.rejects(getDailyStory(f.options), /Commit failed/);
  assert.equal(f.db.documents.size, 0);
  await getDailyStory(f.options);
  assert.equal(f.generations(), 2);
});

test("an ambiguous successful commit preserves the story for recovery", async () => {
  const f = fixture();
  f.db.failCompletion = "after";
  await assert.rejects(getDailyStory(f.options), /Commit response lost/);
  const recovered = await getDailyStory(f.options);
  assert.equal(recovered.title, "A story");
  assert.equal(f.generations(), 1);
});

test("an abandoned request cannot erase or overwrite a newer reservation", async () => {
  const f = fixture();
  let finish;
  let started;
  const ready = new Promise((resolve) => { started = resolve; });
  const first = getDailyStory({
    ...f.options,
    generateStory: () => new Promise((resolve) => { finish = resolve; started(); }),
  });
  await ready;
  f.advance(RESERVATION_TTL_MS + 1);
  const replacement = await getDailyStory(f.options);
  finish({ title: "Expired result" });
  await assert.rejects(first, { statusCode: 409 });
  assert.deepEqual(await getDailyStory(f.options), replacement);
});

test("quotas remain separate across subscribers and UTC dates", async () => {
  const f = fixture();
  await getDailyStory(f.options);
  await getDailyStory({ ...f.options, originalTransactionId: "another-subscriber" });
  f.advance(24 * 60 * 60 * 1000);
  await getDailyStory(f.options);
  assert.equal(f.generations(), 3);
  assert.equal(f.db.documents.size, 3);
});

test("legacy completed quotas without content still enforce the daily allowance", async () => {
  const f = fixture();
  f.db.documents.set("dailyStoryQuota/subscriber_2026-09-05", { status: "completed" });
  await assert.rejects(getDailyStory(f.options), { statusCode: 409 });
  assert.equal(f.generations(), 0);
});
