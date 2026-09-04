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
exports.createTransfer = void 0;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const types_1 = require("../models/types");
const wallet_1 = require("../utils/wallet");
const risk_1 = require("../utils/risk");
const audit_1 = require("../utils/audit");
exports.createTransfer = (0, https_1.onCall)({ region: 'asia-south1' }, async (request) => {
    const { auth, data } = request;
    if (!auth) {
        throw new https_1.HttpsError('unauthenticated', 'Caller must be authenticated.');
    }
    const { requestId, recipientName, recipientPhone, amountPaise } = data;
    if (!requestId || !recipientName || !recipientPhone || !amountPaise || amountPaise <= 0 || amountPaise > types_1.MAX_TRANSFER_PAISE) {
        throw new https_1.HttpsError('invalid-argument', 'Invalid request parameters.');
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
        const txData = existingDoc.data();
        return {
            transactionId: existingDoc.id,
            status: txData.status,
            riskLevel: txData.riskLevel,
            riskReasons: txData.riskReasons,
            escrowExpiresAt: txData.escrowExpiresAt?.toDate().toISOString() || null
        };
    }
    return await db.runTransaction(async (transaction) => {
        const userRef = db.collection('users').doc(auth.uid);
        const userSnap = await transaction.get(userRef);
        if (!userSnap.exists) {
            throw new https_1.HttpsError('not-found', 'Sender user document not found.');
        }
        const userData = userSnap.data();
        if (userData?.role !== 'senior') {
            throw new https_1.HttpsError('permission-denied', 'Only seniors can create transfers.');
        }
        const trustedContacts = userData?.trustedContacts || [];
        const escrowDelayMinutes = userData?.escrowDelayMinutes ?? types_1.DEFAULT_ESCROW_DELAY_MINUTES;
        const linkedGuardianId = userData?.linkedGuardianId || null;
        const hasGuardian = !!linkedGuardianId;
        const wallet = await (0, wallet_1.getOrCreateWallet)(transaction, auth.uid);
        if (wallet.availableBalancePaise < amountPaise) {
            throw new https_1.HttpsError('failed-precondition', 'Insufficient balance');
        }
        const riskResult = (0, risk_1.evaluateRisk)({
            hasGuardian,
            recipientPhone,
            amountPaise,
            trustedContacts,
            isCallActive: false
        });
        const needsReview = (0, risk_1.requiresGuardianReview)(riskResult.riskLevel, hasGuardian);
        const status = needsReview ? types_1.TransactionStatus.REVIEW_REQUIRED : types_1.TransactionStatus.ESCROWED;
        (0, wallet_1.debitAndHold)(transaction, wallet.ref, wallet, amountPaise);
        const now = firestore_1.Timestamp.now();
        const escrowExpiresAt = firestore_1.Timestamp.fromMillis(now.toMillis() + escrowDelayMinutes * 60 * 1000);
        const newTxRef = db.collection('transactions').doc();
        const transactionDoc = {
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
        (0, wallet_1.addLedgerEntry)(transaction, auth.uid, {
            type: types_1.LedgerEntryType.HOLD,
            amountPaise,
            balanceAfterPaise: wallet.availableBalancePaise - amountPaise,
            transactionId: newTxRef.id,
            description: 'Transfer to ' + recipientName,
        });
        await (0, audit_1.createAuditLog)({
            eventType: types_1.AuditEventType.TRANSFER_CREATED,
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
        };
    });
});
//# sourceMappingURL=createTransfer.js.map