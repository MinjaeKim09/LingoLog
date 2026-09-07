"use strict";

const { randomUUID } = require("node:crypto");
const { clientError } = require("./story");

// Longer than the HTTP function's 60-second timeout. An abandoned reservation
// can be retried without allowing two live requests to generate concurrently.
const RESERVATION_TTL_MS = 2 * 60 * 1000;

async function getDailyStory({ db, originalTransactionId, payload, generateStory, serverTimestamp, now = Date.now }) {
  const reservedAt = now();
  const date = new Date(reservedAt).toISOString().slice(0, 10);
  const ref = db.collection("dailyStoryQuota").doc(`${originalTransactionId}_${date}`);
  const reservationID = randomUUID();

  const cachedStory = await db.runTransaction(async (transaction) => {
    const current = (await transaction.get(ref)).data();
    if (current && current.status === "completed") {
      if (!current.story) throw clientError("You have already generated today's story.", 409);
      if (current.languageCode !== payload.languageCode) {
        throw clientError("Today's story was generated in another language. Switch to that language to read it.", 409);
      }
      return current.story;
    }
    const previousReservationTime = current && (current.reservedAt ?? current.createdAt?.toMillis());
    if (current && (previousReservationTime == null || reservedAt - previousReservationTime < RESERVATION_TTL_MS)) {
      throw clientError("Your story is still being generated. Please try again shortly.", 409);
    }
    transaction.set(ref, {
      originalTransactionId, date, languageCode: payload.languageCode,
      createdAt: serverTimestamp(), reservedAt, reservationID, status: "pending",
    });
    return null;
  });
  if (cachedStory) return cachedStory;

  try {
    // Include the original vocabulary so a retry with newly shuffled words does
    // not associate the saved story with words that weren't used to generate it.
    const story = { ...await generateStory(payload), words: payload.words };
    await db.runTransaction(async (transaction) => {
      const current = (await transaction.get(ref)).data();
      if (!current || current.reservationID !== reservationID || current.status !== "pending") {
        throw clientError("The story request expired. Please try again.", 409);
      }
      transaction.update(ref, { story, completedAt: serverTimestamp(), status: "completed" });
    });
    return story;
  } catch (error) {
    // Never delete a completed result, including after an ambiguous commit error,
    // or a reservation now owned by a different request.
    await db.runTransaction(async (transaction) => {
      const current = (await transaction.get(ref)).data();
      if (current?.reservationID === reservationID && current.status === "pending") {
        transaction.delete(ref);
      }
    }).catch((releaseError) => console.error("Failed to release story quota", releaseError));
    throw error;
  }
}

module.exports = { getDailyStory, RESERVATION_TTL_MS };
