import { Timestamp, FieldValue } from "firebase-admin/firestore";

import { onCall, HttpsError } from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import { 
  AddDemoFundsRequest, 
  ModifyTrustedContactsRequest, 
  UpdateEscrowDelayRequest, 
  MAX_DEMO_TOP_UP_PAISE, 
  VALID_ESCROW_DELAYS, 
  AuditEventType, 
  UserDoc,
  LedgerEntryType
} from "../models/types";
import { createAuditLog } from "../utils/audit";
import { getOrCreateWallet, creditWallet, addLedgerEntry } from "../utils/wallet";

export const addDemoFunds = onCall({ region: "asia-south1" }, async (request) => {
  const { auth, data } = request;
  if (!auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const { amountPaise, targetUserId } = data as AddDemoFundsRequest & { targetUserId?: string };
  if (!amountPaise || amountPaise <= 0 || amountPaise > MAX_DEMO_TOP_UP_PAISE) {
    throw new HttpsError("invalid-argument", "Invalid amountPaise");
  }

  const db = admin.firestore();
  
  const targetId = targetUserId || auth.uid;

  if (targetId !== auth.uid) {
    const targetRef = db.collection("users").doc(targetId);
    const targetDoc = await targetRef.get();
    if (!targetDoc.exists || targetDoc.data()?.linkedGuardianId !== auth.uid) {
      throw new HttpsError("permission-denied", "Can only top up yourself or your linked senior");
    }
  }

  await db.runTransaction(async (txn) => {
    const walletData = await getOrCreateWallet(txn, targetId);
    
    creditWallet(txn, walletData.ref, walletData, amountPaise);
    
    addLedgerEntry(txn, targetId, {
      type: LedgerEntryType.TOP_UP,
      amountPaise,
      balanceAfterPaise: walletData.availableBalancePaise + amountPaise,
      transactionId: null,
      description: targetId === auth.uid ? "Demo funds added" : "Demo funds added by Guardian",
    });
  });

  await createAuditLog({
    eventType: AuditEventType.DEMO_FUNDS_ADDED,
    actorId: auth.uid,
    targetId: targetId,
    metadata: { amountPaise }
  });

  return { success: true };
});

export const modifyTrustedContacts = onCall({ region: "asia-south1" }, async (request) => {
  const { auth, data } = request;
  if (!auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const { seniorId, phone, action } = data as ModifyTrustedContactsRequest;
  if (!seniorId || !phone || !['add', 'remove'].includes(action)) {
    throw new HttpsError("invalid-argument", "Invalid arguments");
  }

  const db = admin.firestore();
  
  const seniorRef = db.collection("users").doc(seniorId);
  const seniorDoc = await seniorRef.get();
  
  if (!seniorDoc.exists) {
    throw new HttpsError("not-found", "Senior not found");
  }
  
  const seniorData = seniorDoc.data() as UserDoc;
  if (seniorData.linkedGuardianId !== auth.uid) {
    throw new HttpsError("permission-denied", "Caller is not the linked guardian");
  }

  if (action === 'add') {
    await seniorRef.update({
      trustedContacts: FieldValue.arrayUnion(phone),
      updatedAt: FieldValue.serverTimestamp()
    });
  } else {
    await seniorRef.update({
      trustedContacts: FieldValue.arrayRemove(phone),
      updatedAt: FieldValue.serverTimestamp()
    });
  }

  await createAuditLog({
    eventType: action === 'add' ? AuditEventType.TRUSTED_CONTACT_ADDED : AuditEventType.TRUSTED_CONTACT_REMOVED,
    actorId: auth.uid,
    targetId: seniorId,
    metadata: { phone, action }
  });

  return { success: true };
});

export const updateEscrowDelay = onCall({ region: "asia-south1" }, async (request) => {
  const { auth, data } = request;
  if (!auth) {
    throw new HttpsError("unauthenticated", "User must be authenticated");
  }

  const { seniorId, minutes } = data as UpdateEscrowDelayRequest;
  if (!seniorId || !VALID_ESCROW_DELAYS.includes(minutes as any)) {
    throw new HttpsError("invalid-argument", "Invalid arguments");
  }

  const db = admin.firestore();
  
  const seniorRef = db.collection("users").doc(seniorId);
  const seniorDoc = await seniorRef.get();
  
  if (!seniorDoc.exists) {
    throw new HttpsError("not-found", "Senior not found");
  }
  
  const seniorData = seniorDoc.data() as UserDoc;
  if (seniorData.linkedGuardianId !== auth.uid) {
    throw new HttpsError("permission-denied", "Caller is not the linked guardian");
  }

  await seniorRef.update({
    escrowDelayMinutes: minutes,
    updatedAt: FieldValue.serverTimestamp()
  });

  await createAuditLog({
    eventType: AuditEventType.ESCROW_DELAY_UPDATED,
    actorId: auth.uid,
    targetId: seniorId,
    metadata: { minutes }
  });

  return { success: true };
});
