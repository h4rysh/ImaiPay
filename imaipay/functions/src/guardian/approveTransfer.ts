import { Timestamp, FieldValue } from "firebase-admin/firestore";

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { ApproveTransferRequest, TransactionStatus, TransactionDoc, UserDoc, AuditEventType } from "../models/types";
import { createAuditLog } from "../utils/audit";

export const approveTransfer = onCall({ region: "asia-south1" }, async (request) => {
  const { auth, data } = request;
  if (!auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const { transactionId } = data as ApproveTransferRequest;
  if (!transactionId) {
    throw new HttpsError("invalid-argument", "transactionId is required");
  }

  const db = admin.firestore();

  await db.runTransaction(async (transaction) => {
    const txRef = db.collection("transactions").doc(transactionId);
    const txDoc = await transaction.get(txRef);

    if (!txDoc.exists) {
      throw new HttpsError("not-found", "Transaction not found");
    }

    const txData = txDoc.data() as TransactionDoc;
    if (txData.status !== TransactionStatus.REVIEW_REQUIRED) {
      throw new HttpsError("failed-precondition", "Transaction is not pending review");
    }

    const senderRef = db.collection("users").doc(txData.senderId);
    const senderDoc = await transaction.get(senderRef);
    
    if (!senderDoc.exists) {
      throw new HttpsError("not-found", "Sender not found");
    }

    const senderData = senderDoc.data() as UserDoc;
    if (senderData.linkedGuardianId !== auth.uid) {
      throw new HttpsError("permission-denied", "Only the linked guardian can approve this transfer");
    }

    const holdDurationMinutes = txData.holdDurationMinutes || 0;
    const escrowExpiresAt = holdDurationMinutes > 0
      ? Timestamp.fromMillis(Date.now() + holdDurationMinutes * 60 * 1000)
      : FieldValue.serverTimestamp(); // Or just null? Wait, if 0, maybe it expires immediately.

    transaction.update(txRef, {
      status: TransactionStatus.ESCROWED,
      approvedBy: auth.uid,
      approvedAt: FieldValue.serverTimestamp(),
      escrowExpiresAt: escrowExpiresAt
    });
  });

  await createAuditLog({
    eventType: AuditEventType.GUARDIAN_APPROVED,
    actorId: auth.uid,
    targetId: transactionId,
    metadata: { transactionId }
  });

  return { success: true };
});
