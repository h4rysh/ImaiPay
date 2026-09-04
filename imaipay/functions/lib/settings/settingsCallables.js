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
exports.updateEscrowDelay = exports.modifyTrustedContacts = exports.addDemoFunds = void 0;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const types_1 = require("../models/types");
const audit_1 = require("../utils/audit");
const wallet_1 = require("../utils/wallet");
exports.addDemoFunds = (0, https_1.onCall)({ region: "asia-south1" }, async (request) => {
    const { auth, data } = request;
    if (!auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { amountPaise, targetUserId } = data;
    if (!amountPaise || amountPaise <= 0 || amountPaise > types_1.MAX_DEMO_TOP_UP_PAISE) {
        throw new https_1.HttpsError("invalid-argument", "Invalid amountPaise");
    }
    const db = admin.firestore();
    const targetId = targetUserId || auth.uid;
    if (targetId !== auth.uid) {
        const targetRef = db.collection("users").doc(targetId);
        const targetDoc = await targetRef.get();
        if (!targetDoc.exists || targetDoc.data()?.linkedGuardianId !== auth.uid) {
            throw new https_1.HttpsError("permission-denied", "Can only top up yourself or your linked senior");
        }
    }
    await db.runTransaction(async (txn) => {
        const walletData = await (0, wallet_1.getOrCreateWallet)(txn, targetId);
        (0, wallet_1.creditWallet)(txn, walletData.ref, walletData, amountPaise);
        (0, wallet_1.addLedgerEntry)(txn, targetId, {
            type: types_1.LedgerEntryType.TOP_UP,
            amountPaise,
            balanceAfterPaise: walletData.availableBalancePaise + amountPaise,
            transactionId: null,
            description: targetId === auth.uid ? "Demo funds added" : "Demo funds added by Guardian",
        });
    });
    await (0, audit_1.createAuditLog)({
        eventType: types_1.AuditEventType.DEMO_FUNDS_ADDED,
        actorId: auth.uid,
        targetId: targetId,
        metadata: { amountPaise }
    });
    return { success: true };
});
exports.modifyTrustedContacts = (0, https_1.onCall)({ region: "asia-south1" }, async (request) => {
    const { auth, data } = request;
    if (!auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { seniorId, phone, action } = data;
    if (!seniorId || !phone || !['add', 'remove'].includes(action)) {
        throw new https_1.HttpsError("invalid-argument", "Invalid arguments");
    }
    const db = admin.firestore();
    const seniorRef = db.collection("users").doc(seniorId);
    const seniorDoc = await seniorRef.get();
    if (!seniorDoc.exists) {
        throw new https_1.HttpsError("not-found", "Senior not found");
    }
    const seniorData = seniorDoc.data();
    if (seniorData.linkedGuardianId !== auth.uid) {
        throw new https_1.HttpsError("permission-denied", "Caller is not the linked guardian");
    }
    if (action === 'add') {
        await seniorRef.update({
            trustedContacts: firestore_1.FieldValue.arrayUnion(phone),
            updatedAt: firestore_1.FieldValue.serverTimestamp()
        });
    }
    else {
        await seniorRef.update({
            trustedContacts: firestore_1.FieldValue.arrayRemove(phone),
            updatedAt: firestore_1.FieldValue.serverTimestamp()
        });
    }
    await (0, audit_1.createAuditLog)({
        eventType: action === 'add' ? types_1.AuditEventType.TRUSTED_CONTACT_ADDED : types_1.AuditEventType.TRUSTED_CONTACT_REMOVED,
        actorId: auth.uid,
        targetId: seniorId,
        metadata: { phone, action }
    });
    return { success: true };
});
exports.updateEscrowDelay = (0, https_1.onCall)({ region: "asia-south1" }, async (request) => {
    const { auth, data } = request;
    if (!auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { seniorId, minutes } = data;
    if (!seniorId || !types_1.VALID_ESCROW_DELAYS.includes(minutes)) {
        throw new https_1.HttpsError("invalid-argument", "Invalid arguments");
    }
    const db = admin.firestore();
    const seniorRef = db.collection("users").doc(seniorId);
    const seniorDoc = await seniorRef.get();
    if (!seniorDoc.exists) {
        throw new https_1.HttpsError("not-found", "Senior not found");
    }
    const seniorData = seniorDoc.data();
    if (seniorData.linkedGuardianId !== auth.uid) {
        throw new https_1.HttpsError("permission-denied", "Caller is not the linked guardian");
    }
    await seniorRef.update({
        escrowDelayMinutes: minutes,
        updatedAt: firestore_1.FieldValue.serverTimestamp()
    });
    await (0, audit_1.createAuditLog)({
        eventType: types_1.AuditEventType.ESCROW_DELAY_UPDATED,
        actorId: auth.uid,
        targetId: seniorId,
        metadata: { minutes }
    });
    return { success: true };
});
//# sourceMappingURL=settingsCallables.js.map