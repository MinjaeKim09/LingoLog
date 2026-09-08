"use strict";
const test = require("node:test");
const assert = require("node:assert/strict");
const { Environment, VerificationException, VerificationStatus } = require("@apple/app-store-server-library");
const { verifySubscriptionTransaction, PRODUCT_ID } = require("../subscription");
const active = { productId: PRODUCT_ID, originalTransactionId: "123", expiresDate: 2000 };

test("production verifies sandbox only after a verified environment mismatch", async () => {
  const calls = [];
  const result = await verifySubscriptionTransaction("signed", {
    environment: Environment.PRODUCTION, now: () => 1000,
    makeVerifier: (environment) => ({ verifyAndDecodeTransaction: async () => {
      calls.push(environment);
      if (environment === Environment.PRODUCTION) throw new VerificationException(VerificationStatus.INVALID_ENVIRONMENT);
      return active;
    } }),
  });
  assert.deepEqual(calls, [Environment.PRODUCTION, Environment.SANDBOX]);
  assert.equal(result, active);
});
test("bad signatures and network failures never fall back", async () => {
  for (const error of [new VerificationException(VerificationStatus.VERIFICATION_FAILURE), new Error("network")]) {
    let calls = 0;
    await assert.rejects(verifySubscriptionTransaction("invalid", {
      environment: Environment.PRODUCTION,
      makeVerifier: () => ({ verifyAndDecodeTransaction: async () => { calls++; throw error; } }),
    }), (actual) => actual === error);
    assert.equal(calls, 1);
  }
});
test("only active, unrevoked purchases of the expected product unlock stories", async () => {
  for (const patch of [{ expiresDate: 1000 }, { expiresDate: NaN }, { productId: "other" }, { revocationDate: 900 }, { originalTransactionId: "" }]) {
    await assert.rejects(verifySubscriptionTransaction("signed", {
      environment: Environment.SANDBOX, now: () => 1000,
      makeVerifier: () => ({ verifyAndDecodeTransaction: async () => ({ ...active, ...patch }) }),
    }), /not active/);
  }
});
test("configuration typos fail closed", async () => {
  await assert.rejects(verifySubscriptionTransaction("signed", { environment: "production" }), /must be/);
});
