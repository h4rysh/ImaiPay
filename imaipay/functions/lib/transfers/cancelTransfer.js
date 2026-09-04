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
exports.cancelTransfer = void 0;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const types_1 = require("../models/types");
const wallet_1 = require("../utils/wallet");
const audit_1 = require("../utils/audit");
exports.cancelTransfer = (0, https_1.onCall)({ region: 'asia-south1' }, async (request) => {
    const { auth, data } = request;
    if (!auth) {
        throw new https_1.HttpsError('unauthenticated', 'Caller must be authenticated.');
    }
    const { transactionId } = data;
    if (!transactionId) {
        throw new https_1.HttpsError('invalid-argument', 'transactionId is required.');
    }
    const db = admin.firestore();
    return await db.runTransaction(async (transaction) => {
        const txRef = db.collection('transactions').doc(transactionId);
        const txSnap = await transaction.get(txRef);
        if (!txSnap.exists) {
            throw new https_1.HttpsError('not-found', 'Transaction not found.');
        }
        const txData = txSnap.data();
        if (txData.senderId !== auth.uid) {
            throw new https_1.HttpsError('permission-denied', 'Not authorized to cancel this transfer.');
        }
        if (txData.status !== types_1.TransactionStatus.ESCROWED && txData.status !== types_1.TransactionStatus.REVIEW_REQUIRED) {
            throw new https_1.HttpsError('failed-precondition', 'Transaction cannot be cancelled in its current state.');
        }
        if (txData.status === types_1.TransactionStatus.ESCROWED) {
            const now = firestore_1.Timestamp.now();
            if (txData.escrowExpiresAt && txData.escrowExpiresAt.toMillis() <= now.toMillis()) {
                throw new https_1.HttpsError('failed-precondition', 'Escrow period has expired.');
            }
        }
        const wallet = await (0, wallet_1.getOrCreateWallet)(transaction, auth.uid);
        (0, wallet_1.releaseHoldAndRefund)(transaction, wallet.ref, wallet, txData.amountPaise);
        (0, wallet_1.addLedgerEntry)(transaction, auth.uid, {
            type: types_1.LedgerEntryType.REFUND,
            amountPaise: txData.amountPaise,
            balanceAfterPaise: wallet.availableBalancePaise + txData.amountPaise,
            transactionId: transactionId,
            description: `Refund for cancelled transfer`,
        });
        const now = firestore_1.Timestamp.now();
        transaction.update(txRef, {
            status: types_1.TransactionStatus.CANCELLED,
            cancelledAt: now,
            updatedAt: now,
            refundedAt: now
        });
        await (0, audit_1.createAuditLog)({
            eventType: types_1.AuditEventType.TRANSFER_CANCELLED,
            actorId: auth.uid,
            targetId: transactionId,
            metadata: { amountPaise: txData.amountPaise }
        });
        return { success: true };
    });
});
//# sourceMappingURL=cancelTransfer.js.map