"use strict";

const { getAppCheck } = require("firebase-admin/app-check");

function clientError(message, statusCode = 400) {
  const error = new Error(message);
  error.statusCode = statusCode;
  return error;
}

async function verifyAppAttestation(req, expectedAppId) {
  const token = typeof req.get === "function" ? req.get("X-Firebase-AppCheck") : undefined;
  if (!token || !token.trim()) {
    throw clientError("A valid app attestation is required.", 401);
  }

  try {
    const decodedToken = await getAppCheck().verifyToken(token);
    if (decodedToken.appId !== expectedAppId) {
      throw clientError("A valid app attestation is required.", 401);
    }
    return decodedToken.appId;
  } catch (error) {
    if (error.statusCode) {
      throw error;
    }
    throw clientError("A valid app attestation is required.", 401);
  }
}

function requestClientKey(req) {
  const forwarded = typeof req.get === "function" ? req.get("X-Forwarded-For") : "";
  const candidate = (forwarded || req.ip || "unknown").split(",")[0].trim();
  return candidate.slice(0, 128) || "unknown";
}

module.exports = { clientError, requestClientKey, verifyAppAttestation };
