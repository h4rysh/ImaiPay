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
exports.denyTransfer = void 0;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const types_1 = require("../models/types");
const audit_1 = require("../utils/audit");
const wallet_1 = require("../utils/wallet");
exports.denyTransfer = (0, https_1.onCall)({ region: "asia-south1" }, async (request) => {
    const { auth, data } = request;
    if (!auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { transactionId } = data;
    if (!transactionId) {
        throw new https_1.HttpsError("invalid-argument", "transactionId is required");
    }
    const db = admin.firestore();
    await db.runTransaction(async (transaction) => {
        const txRef = db.collection("transactions").doc(transactionId);
        const txDoc = await transaction.get(txRef);
        if (!txDoc.exists) {
            throw new https_1.HttpsError("not-found", "Transaction not found");
        }
        const txData = txDoc.data();
        if (txData.status !== types_1.TransactionStatus.REVIEW_REQUIRED) {
            throw new https_1.HttpsError("failed-precondition", "Transaction is not pending review");
        }
        const senderRef = db.collection("users").doc(txData.senderId);
        const senderDoc = await transaction.get(senderRef);
        if (!senderDoc.exists) {
            throw new https_1.HttpsError("not-found", "Sender not found");
        }
        const senderData = senderDoc.data();
        if (senderData.linkedGuardianId !== auth.uid) {
            throw new https_1.HttpsError("permission-denied", "Only the linked guardian can deny this transfer");
        }
        const walletData = await (0, wallet_1.getOrCreateWallet)(transaction, txData.senderId);
        (0, wallet_1.releaseHoldAndRefund)(transaction, walletData.ref, walletData, txData.amountPaise);
        (0, wallet_1.addLedgerEntry)(transaction, txData.senderId, {
            type: types_1.LedgerEntryType.REFUND,
            amountPaise: txData.amountPaise,
            balanceAfterPaise: walletData.availableBalancePaise + txData.amountPaise,
            transactionId: transactionId,
            description: "Transfer denied by guardian",
        });
        transaction.update(txRef, {
            status: types_1.TransactionStatus.DENIED,
            deniedBy: auth.uid,
            deniedAt: firestore_1.FieldValue.serverTimestamp()
        });
    });
    await (0, audit_1.createAuditLog)({
        eventType: types_1.AuditEventType.GUARDIAN_DENIED,
        actorId: auth.uid,
        targetId: transactionId,
        metadata: { transactionId }
    });
    return { success: true };
});
//# sourceMappingURL=denyTransfer.js.map