import { Timestamp, FieldValue } from "firebase-admin/firestore";

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { UserDoc, UserRole, PairingSessionDoc, AuditEventType, PAIRING_SESSION_EXPIRY_SECONDS, MAX_PAIRING_ATTEMPTS } from "../models/types";
import { createAuditLog } from "../utils/audit";

export const createPairingSession = onCall({ region: "asia-south1" }, async (request) => {
  const { auth } = request;
  if (!auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const db = admin.firestore();

  const userRef = db.collection("users").doc(auth.uid);
  const userDoc = await userRef.get();
  
  if (!userDoc.exists) {
    throw new HttpsError("not-found", "User not found");
  }

  const userData = userDoc.data() as UserDoc;
  if (userData.role !== UserRole.SENIOR) {
    throw new HttpsError("permission-denied", "Only seniors can create a pairing session");
  }

  const code = Math.floor(100000 + Math.random() * 900000).toString();
  const expiresAt = Timestamp.fromMillis(Date.now() + PAIRING_SESSION_EXPIRY_SECONDS * 1000);

  const batch = db.batch();

  // Invalidate old unused sessions
  const oldSessions = await db.collection("pairingSessions")
    .where("seniorId", "==", auth.uid)
    .where("used", "==", false)
    .get();

  oldSessions.docs.forEach((doc) => {
    batch.update(doc.ref, { used: true });
  });

  const sessionRef = db.collection("pairingSessions").doc();
  const sessionData: PairingSessionDoc = {
    seniorId: auth.uid,
    code,
    expiresAt,
    used: false,
    attempts: 0,
    maxAttempts: MAX_PAIRING_ATTEMPTS,
    createdAt: FieldValue.serverTimestamp() as Timestamp
  };

  batch.set(sessionRef, sessionData);

  await batch.commit();

  await createAuditLog({
    eventType: AuditEventType.PAIRING_SESSION_CREATED,
    actorId: auth.uid,
    targetId: sessionRef.id,
    metadata: { code } // you might not want to log the code in reality, but just following instructions
  });

  return { code, expiresInSeconds: PAIRING_SESSION_EXPIRY_SECONDS };
});
