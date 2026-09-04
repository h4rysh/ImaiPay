import { Timestamp } from "firebase-admin/firestore";

import { onCall, HttpsError } from 'firebase-functions/v2/https';
import * as admin from 'firebase-admin';
import { CancelTransferRequest, TransactionStatus, TransactionDoc, AuditEventType, LedgerEntryType } from '../models/types';
import { getOrCreateWallet, releaseHoldAndRefund, addLedgerEntry } from '../utils/wallet';
import { createAuditLog } from '../utils/audit';

export const cancelTransfer = onCall({ region: 'asia-south1' }, async (request) => {
  const { auth, data } = request;
  
  if (!auth) {
    throw new HttpsError('unauthenticated', 'Caller must be authenticated.');
  }
  
  const { transactionId } = data as CancelTransferRequest;
  if (!transactionId) {
    throw new HttpsError('invalid-argument', 'transactionId is required.');
  }

  const db = admin.firestore();

  return await db.runTransaction(async (transaction) => {
    const txRef = db.collection('transactions').doc(transactionId);
    const txSnap = await transaction.get(txRef);
    
    if (!txSnap.exists) {
      throw new HttpsError('not-found', 'Transaction not found.');
    }
    
    const txData = txSnap.data() as TransactionDoc;
    
    if (txData.senderId !== auth.uid) {
      throw new HttpsError('permission-denied', 'Not authorized to cancel this transfer.');
    }
    
    if (txData.status !== TransactionStatus.ESCROWED && txData.status !== TransactionStatus.REVIEW_REQUIRED) {
      throw new HttpsError('failed-precondition', 'Transaction cannot be cancelled in its current state.');
    }
    
    if (txData.status === TransactionStatus.ESCROWED) {
      const now = Timestamp.now();
      if (txData.escrowExpiresAt && txData.escrowExpiresAt.toMillis() <= now.toMillis()) {
        throw new HttpsError('failed-precondition', 'Escrow period has expired.');
      }
    }
    
    const wallet = await getOrCreateWallet(transaction, auth.uid);
    releaseHoldAndRefund(transaction, wallet.ref, wallet, txData.amountPaise);
    
    addLedgerEntry(transaction, auth.uid, {
      type: LedgerEntryType.REFUND,
      amountPaise: txData.amountPaise,
      balanceAfterPaise: wallet.availableBalancePaise + txData.amountPaise,
      transactionId: transactionId,
      description: `Refund for cancelled transfer`,
    });
    
    const now = Timestamp.now();
    transaction.update(txRef, {
      status: TransactionStatus.CANCELLED,
      cancelledAt: now,
      updatedAt: now,
      refundedAt: now
    });
    
    await createAuditLog({
      eventType: AuditEventType.TRANSFER_CANCELLED,
      actorId: auth.uid,
      targetId: transactionId,
      metadata: { amountPaise: txData.amountPaise }
    });
    
    return { success: true };
  });
});
