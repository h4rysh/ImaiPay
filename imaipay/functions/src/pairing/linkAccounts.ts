import { Timestamp, FieldValue } from "firebase-admin/firestore";

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { LinkAccountsRequest, UserRole, UserDoc, PairingSessionDoc, AuditEventType } from "../models/types";
import { createAuditLog } from "../utils/audit";

export const linkAccounts = onCall({ region: "asia-south1" }, async (request) => {
  const { auth, data } = request;
  if (!auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const { code } = data as LinkAccountsRequest;
  if (!code) {
    throw new HttpsError("invalid-argument", "code is required");
  }

  const db = admin.firestore();

  const callerRef = db.collection("users").doc(auth.uid);
  const callerDoc = await callerRef.get();
  
  if (!callerDoc.exists) {
    throw new HttpsError("not-found", "Guardian user not found");
  }

  const callerData = callerDoc.data() as UserDoc;
  if (callerData.role !== UserRole.GUARDIAN) {
    throw new HttpsError("permission-denied", "Only guardians can link accounts");
  }

  const now = Timestamp.now();
  
  // OUTSIDE transaction: find session
  const sessionQuery = await db.collection("pairingSessions")
    .where("code", "==", code)
    .where("used", "==", false)
    .where("expiresAt", ">", now)
    .limit(1)
    .get();

  if (sessionQuery.empty) {
    throw new HttpsError("not-found", "Invalid or expired pairing code");
  }

  const sessionId = sessionQuery.docs[0].id;
  let seniorId = "";

  await db.runTransaction(async (transaction) => {
    const sessionRef = db.collection("pairingSessions").doc(sessionId);
    const sessionDoc = await transaction.get(sessionRef);

    if (!sessionDoc.exists) {
      throw new HttpsError("not-found", "Session not found");
    }

    const sessionData = sessionDoc.data() as PairingSessionDoc;
    
    // Check validity again inside transaction
    const currentTime = Timestamp.now();
    if (sessionData.used || sessionData.expiresAt.toMillis() <= currentTime.toMillis()) {
      throw new HttpsError("failed-precondition", "Invalid or expired pairing code");
    }

    const newAttempts = (sessionData.attempts || 0) + 1;
    seniorId = sessionData.seniorId;
    
    if (newAttempts > sessionData.maxAttempts) {
      transaction.update(sessionRef, { used: true, attempts: newAttempts });
      throw new HttpsError("permission-denied", "Too many attempts");
    }

    const seniorRef = db.collection("users").doc(seniorId);
    const seniorDoc = await transaction.get(seniorRef);
    if (!seniorDoc.exists) {
      throw new HttpsError("not-found", "Senior not found");
    }

    // Link accounts
    transaction.update(seniorRef, {
      linkedGuardianId: auth.uid,
      updatedAt: FieldValue.serverTimestamp()
    });

    transaction.update(callerRef, {
      linkedSeniorIds: FieldValue.arrayUnion(seniorId),
      updatedAt: FieldValue.serverTimestamp()
    });

    transaction.update(sessionRef, {
      used: true,
      attempts: newAttempts
    });
  });

  await createAuditLog({
    eventType: AuditEventType.ACCOUNT_LINKED,
    actorId: auth.uid,
    targetId: seniorId,
    metadata: { sessionId, code }
  });

  return { success: true };
});

export const unlinkFromGuardian = onCall({ region: "asia-south1" }, async (request) => {
  const { auth } = request;
  if (!auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const db = admin.firestore();
  
  const callerRef = db.collection("users").doc(auth.uid);
  let linkedGuardianId = "";

  await db.runTransaction(async (transaction) => {
    const callerDoc = await transaction.get(callerRef);
    if (!callerDoc.exists) {
      throw new HttpsError("not-found", "User not found");
    }

    const callerData = callerDoc.data() as UserDoc;
    if (callerData.role !== UserRole.SENIOR) {
      throw new HttpsError("permission-denied", "Only seniors can unlink from guardian");
    }

    linkedGuardianId = callerData.linkedGuardianId || "";
    if (!linkedGuardianId) {
      throw new HttpsError("failed-precondition", "No guardian linked");
    }

    const guardianRef = db.collection("users").doc(linkedGuardianId);
    
    transaction.update(callerRef, {
      linkedGuardianId: null,
      updatedAt: FieldValue.serverTimestamp()
    });

    transaction.update(guardianRef, {
      linkedSeniorIds: FieldValue.arrayRemove(auth.uid),
      updatedAt: FieldValue.serverTimestamp()
    });
  });

  if (linkedGuardianId) {
    await createAuditLog({
      eventType: AuditEventType.ACCOUNT_UNLINKED,
      actorId: auth.uid,
      targetId: linkedGuardianId,
      metadata: { reason: "User requested unlink" }
    });
  }

  return { success: true };
});
