import { Timestamp, FieldValue } from "firebase-admin/firestore";

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { DenyTransferRequest, TransactionStatus, TransactionDoc, UserDoc, AuditEventType, LedgerEntryType } from "../models/types";
import { createAuditLog } from "../utils/audit";
import { getOrCreateWallet, releaseHoldAndRefund, addLedgerEntry } from "../utils/wallet";

export const denyTransfer = onCall({ region: "asia-south1" }, async (request) => {
  const { auth, data } = request;
  if (!auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const { transactionId } = data as DenyTransferRequest;
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
      throw new HttpsError("permission-denied", "Only the linked guardian can deny this transfer");
    }

    const walletData = await getOrCreateWallet(transaction, txData.senderId);

    releaseHoldAndRefund(transaction, walletData.ref, walletData, txData.amountPaise);
    
    addLedgerEntry(transaction, txData.senderId, {
      type: LedgerEntryType.REFUND,
      amountPaise: txData.amountPaise,
      balanceAfterPaise: walletData.availableBalancePaise + txData.amountPaise,
      transactionId: transactionId,
      description: "Transfer denied by guardian",
    });

    transaction.update(txRef, {
      status: TransactionStatus.DENIED,
      deniedBy: auth.uid,
      deniedAt: FieldValue.serverTimestamp()
    });
  });

  await createAuditLog({
    eventType: AuditEventType.GUARDIAN_DENIED,
    actorId: auth.uid,
    targetId: transactionId,
    metadata: { transactionId }
  });

  return { success: true };
});
