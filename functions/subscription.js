"use strict";

const { Environment, VerificationException, VerificationStatus } = require("@apple/app-store-server-library");
const { clientError } = require("./story");
const PRODUCT_ID = "com.lingolog.dailystories.monthly";

async function verifySubscriptionTransaction(jws, { environment, makeVerifier, now = Date.now }) {
  if (![Environment.PRODUCTION, Environment.SANDBOX].includes(environment)) {
    throw new Error("APP_STORE_ENVIRONMENT must be Production or Sandbox.");
  }
  let transaction;
  try {
    transaction = await makeVerifier(environment).verifyAndDecodeTransaction(jws);
  } catch (error) {
    // App Review and TestFlight use sandbox transactions even when the live
    // service handles production purchases. Never retry an invalid signature.
    if (environment !== Environment.PRODUCTION || !(error instanceof VerificationException)
        || error.status !== VerificationStatus.INVALID_ENVIRONMENT) throw error;
    transaction = await makeVerifier(Environment.SANDBOX).verifyAndDecodeTransaction(jws);
  }
  if (transaction.productId !== PRODUCT_ID || transaction.revocationDate != null
      || !Number.isFinite(transaction.expiresDate) || transaction.expiresDate <= now()
      || !transaction.originalTransactionId) {
    throw clientError("Daily Stories subscription is not active.", 403);
  }
  return transaction;
}

module.exports = { verifySubscriptionTransaction, PRODUCT_ID };
