"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
exports.settleTransfers = void 0;
const firestore_1 = require("firebase-admin/firestore");
const scheduler_1 = require("firebase-functions/v2/scheduler");
const admin = __importStar(require("firebase-admin"));
const types_1 = require("../models/types");
const wallet_1 = require("../utils/wallet");
const audit_1 = require("../utils/audit");
exports.settleTransfers = (0, scheduler_1.onSchedule)({
    schedule: 'every 1 minutes',
    region: 'asia-south1'
}, async (event) => {
    const db = admin.firestore();
    const now = firestore_1.Timestamp.now();
    const query = db.collection('transactions')
        .where('status', '==', types_1.TransactionStatus.ESCROWED)
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
                if (!txSnap.exists)
                    return;
                const txData = txSnap.data();
                if (txData.status !== types_1.TransactionStatus.ESCROWED) {
                    return; // Status changed since query
                }
                const wallet = await (0, wallet_1.getOrCreateWallet)(transaction, txData.senderId);
                (0, wallet_1.settleHold)(transaction, wallet.ref, wallet, txData.amountPaise);
                (0, wallet_1.addLedgerEntry)(transaction, txData.senderId, {
                    type: types_1.LedgerEntryType.SETTLEMENT,
                    amountPaise: txData.amountPaise,
                    balanceAfterPaise: wallet.availableBalancePaise, // Available balance is unaffected
                    transactionId: txId,
                    description: `Settlement for transfer`,
                });
                const currentNow = firestore_1.Timestamp.now();
                transaction.update(doc.ref, {
                    status: types_1.TransactionStatus.SETTLED,
                    settledAt: currentNow,
                    updatedAt: currentNow
                });
                await (0, audit_1.createAuditLog)({
                    eventType: types_1.AuditEventType.TRANSFER_SETTLED,
                    actorId: 'system',
                    targetId: txId,
                    metadata: { amountPaise: txData.amountPaise }
                });
            });
            settledCount++;
        }
        catch (error) {
            console.error(`Failed to settle transaction ${txId}:`, error);
        }
    }
    console.log(`Settled ${settledCount} transactions.`);
});
//# sourceMappingURL=settleTransfers.js.map