import { Timestamp } from "firebase-admin/firestore";

import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';
import { TransactionStatus, TransactionDoc, AuditEventType, LedgerEntryType } from '../models/types';
import { getOrCreateWallet, settleHold, addLedgerEntry } from '../utils/wallet';
import { createAuditLog } from '../utils/audit';

export const settleTransfers = onSchedule({
  schedule: 'every 1 minutes',
  region: 'asia-south1'
}, async (event) => {
  const db = admin.firestore();
  const now = Timestamp.now();
  
  const query = db.collection('transactions')
    .where('status', '==', TransactionStatus.ESCROWED)
    .where('escrowExpiresAt', '<=', now)
    .limit(50);
    
  const snap = await query.get();
  
  if (snap.empty) {
    console.log('No transactions to settle.');
    return;
  }
  
  let settledCount = 0;
  
  for (const doc of snap.docs) {
    const txId = doc.id;
    try {
      await db.runTransaction(async (transaction) => {
        const txSnap = await transaction.get(doc.ref);
        if (!txSnap.exists) return;
        
        const txData = txSnap.data() as TransactionDoc;
        
        if (txData.status !== TransactionStatus.ESCROWED) {
          return; // Status changed since query
        }
        
        const wallet = await getOrCreateWallet(transaction, txData.senderId);
        settleHold(transaction, wallet.ref, wallet, txData.amountPaise);
        
        addLedgerEntry(transaction, txData.senderId, {
          type: LedgerEntryType.SETTLEMENT,
          amountPaise: txData.amountPaise,
          balanceAfterPaise: wallet.availableBalancePaise, // Available balance is unaffected
          transactionId: txId,
          description: `Settlement for transfer`,
        });
        
        const currentNow = Timestamp.now();
        transaction.update(doc.ref, {
          status: TransactionStatus.SETTLED,
          settledAt: currentNow,
          updatedAt: currentNow
        });
        
        await createAuditLog({
          eventType: AuditEventType.TRANSFER_SETTLED,
          actorId: 'system',
          targetId: txId,
          metadata: { amountPaise: txData.amountPaise }
        });
      });
      settledCount++;
    } catch (error) {
      console.error(`Failed to settle transaction ${txId}:`, error);
    }
  }
  
  console.log(`Settled ${settledCount} transactions.`);
});
