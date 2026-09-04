import { Timestamp } from "firebase-admin/firestore";

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import {
  CreateTransferRequest,
  CreateTransferResponse,
  TransactionStatus,
  TransactionDoc,
  MAX_TRANSFER_PAISE,
  DEFAULT_ESCROW_DELAY_MINUTES,
  AuditEventType,
  LedgerEntryType
} from '../models/types';
import { getOrCreateWallet, debitAndHold, addLedgerEntry } from '../utils/wallet';
import { evaluateRisk, requiresGuardianReview } from '../utils/risk';
import { createAuditLog } from '../utils/audit';

export const createTransfer = onCall({ region: 'asia-south1' }, async (request) => {
  const { auth, data } = request;
  
  if (!auth) {
    throw new HttpsError('unauthenticated', 'Caller must be authenticated.');
  }
  
  const { requestId, recipientName, recipientPhone, amountPaise } = data as CreateTransferRequest;
  
  if (!requestId || !recipientName || !recipientPhone || !amountPaise || amountPaise <= 0 || amountPaise > MAX_TRANSFER_PAISE) {
    throw new HttpsError('invalid-argument', 'Invalid request parameters.');
  }

  const db = admin.firestore();
  
  // Idempotency check outside transaction
  const txQuery = await db.collection('transactions')
    .where('requestId', '==', requestId)
    .where('senderId', '==', auth.uid)
    .limit(1)
    .get();

  if (!txQuery.empty) {
    const existingDoc = txQuery.docs[0];
    const txData = existingDoc.data() as TransactionDoc;
    return {
      transactionId: existingDoc.id,
      status: txData.status,
      riskLevel: txData.riskLevel!,
      riskReasons: txData.riskReasons,
      escrowExpiresAt: txData.escrowExpiresAt?.toDate().toISOString() || null
    } as CreateTransferResponse;
  }

  return await db.runTransaction(async (transaction) => {
    const userRef = db.collection('users').doc(auth.uid);
    const userSnap = await transaction.get(userRef);
    
    if (!userSnap.exists) {
      throw new HttpsError('not-found', 'Sender user document not found.');
    }
    
    const userData = userSnap.data() as any;
    if (userData?.role !== 'senior') {
      throw new HttpsError('permission-denied', 'Only seniors can create transfers.');
    }
    
    const trustedContacts: string[] = userData?.trustedContacts || [];
    const escrowDelayMinutes: number = userData?.escrowDelayMinutes ?? DEFAULT_ESCROW_DELAY_MINUTES;
    const linkedGuardianId: string | null = userData?.linkedGuardianId || null;
    const hasGuardian = !!linkedGuardianId;
    
    const wallet = await getOrCreateWallet(transaction, auth.uid);
    
    if (wallet.availableBalancePaise < amountPaise) {
      throw new HttpsError('failed-precondition', 'Insufficient balance');
    }
    
    const riskResult = evaluateRisk({
      hasGuardian,
      recipientPhone,
      amountPaise,
      trustedContacts,
      isCallActive: false
    });
    
    const needsReview = requiresGuardianReview(riskResult.riskLevel, hasGuardian);
    const status = needsReview ? TransactionStatus.REVIEW_REQUIRED : TransactionStatus.ESCROWED;
    
    debitAndHold(transaction, wallet.ref, wallet, amountPaise);
    
    const now = Timestamp.now();
    const escrowExpiresAt = Timestamp.fromMillis(now.toMillis() + escrowDelayMinutes * 60 * 1000);
    
    const newTxRef = db.collection('transactions').doc();
    const transactionDoc: TransactionDoc = {
      requestId,
      senderId: auth.uid,
      recipientName,
      recipientPhone,
      amountPaise,
      currency: 'INR',
      status,
      riskLevel: riskResult.riskLevel,
      riskReasons: riskResult.riskReasons,
      guardianId: linkedGuardianId,
      escrowExpiresAt,
      holdDurationMinutes: escrowDelayMinutes,
      createdAt: now,
      updatedAt: now,
      approvedBy: null,
      approvedAt: null,
      deniedBy: null,
      deniedAt: null,
      cancelledAt: null,
      settledAt: null,
      refundedAt: null
    };
    
    transaction.set(newTxRef, transactionDoc);

    addLedgerEntry(transaction, auth.uid, {
      type: LedgerEntryType.HOLD,
      amountPaise,
      balanceAfterPaise: wallet.availableBalancePaise - amountPaise,
      transactionId: newTxRef.id,
      description: 'Transfer to ' + recipientName,
    });
    
    await createAuditLog({
      eventType: AuditEventType.TRANSFER_CREATED,
      actorId: auth.uid,
      targetId: newTxRef.id,
      metadata: { requestId, amountPaise, status }
    });
    
    return {
      transactionId: newTxRef.id,
      status,
      riskLevel: riskResult.riskLevel,
      riskReasons: riskResult.riskReasons,
      escrowExpiresAt: escrowExpiresAt.toDate().toISOString()
    } as CreateTransferResponse;
  });
});
