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
exports.unlinkFromGuardian = exports.linkAccounts = void 0;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const types_1 = require("../models/types");
const audit_1 = require("../utils/audit");
exports.linkAccounts = (0, https_1.onCall)({ region: "asia-south1" }, async (request) => {
    const { auth, data } = request;
    if (!auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { code } = data;
    if (!code) {
        throw new https_1.HttpsError("invalid-argument", "code is required");
    }
    const db = admin.firestore();
    const callerRef = db.collection("users").doc(auth.uid);
    const callerDoc = await callerRef.get();
    if (!callerDoc.exists) {
        throw new https_1.HttpsError("not-found", "Guardian user not found");
    }
    const callerData = callerDoc.data();
    if (callerData.role !== types_1.UserRole.GUARDIAN) {
        throw new https_1.HttpsError("permission-denied", "Only guardians can link accounts");
    }
    const now = firestore_1.Timestamp.now();
    // OUTSIDE transaction: find session
    const sessionQuery = await db.collection("pairingSessions")
        .where("code", "==", code)
        .where("used", "==", false)
        .where("expiresAt", ">", now)
        .limit(1)
        .get();
    if (sessionQuery.empty) {
        throw new https_1.HttpsError("not-found", "Invalid or expired pairing code");
    }
    const sessionId = sessionQuery.docs[0].id;
    let seniorId = "";
    await db.runTransaction(async (transaction) => {
        const sessionRef = db.collection("pairingSessions").doc(sessionId);
        const sessionDoc = await transaction.get(sessionRef);
        if (!sessionDoc.exists) {
            throw new https_1.HttpsError("not-found", "Session not found");
        }
        const sessionData = sessionDoc.data();
        // Check validity again inside transaction
        const currentTime = firestore_1.Timestamp.now();
        if (sessionData.used || sessionData.expiresAt.toMillis() <= currentTime.toMillis()) {
            throw new https_1.HttpsError("failed-precondition", "Invalid or expired pairing code");
        }
        const newAttempts = (sessionData.attempts || 0) + 1;
        seniorId = sessionData.seniorId;
        if (newAttempts > sessionData.maxAttempts) {
            transaction.update(sessionRef, { used: true, attempts: newAttempts });
            throw new https_1.HttpsError("permission-denied", "Too many attempts");
        }
        const seniorRef = db.collection("users").doc(seniorId);
        const seniorDoc = await transaction.get(seniorRef);
        if (!seniorDoc.exists) {
            throw new https_1.HttpsError("not-found", "Senior not found");
        }
        // Link accounts
        transaction.update(seniorRef, {
            linkedGuardianId: auth.uid,
            updatedAt: firestore_1.FieldValue.serverTimestamp()
        });
        transaction.update(callerRef, {
            linkedSeniorIds: firestore_1.FieldValue.arrayUnion(seniorId),
            updatedAt: firestore_1.FieldValue.serverTimestamp()
        });
        transaction.update(sessionRef, {
            used: true,
            attempts: newAttempts
        });
    });
    await (0, audit_1.createAuditLog)({
        eventType: types_1.AuditEventType.ACCOUNT_LINKED,
        actorId: auth.uid,
        targetId: seniorId,
        metadata: { sessionId, code }
    });
    return { success: true };
});
exports.unlinkFromGuardian = (0, https_1.onCall)({ region: "asia-south1" }, async (request) => {
    const { auth } = request;
    if (!auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    const db = admin.firestore();
    const callerRef = db.collection("users").doc(auth.uid);
    let linkedGuardianId = "";
    await db.runTransaction(async (transaction) => {
        const callerDoc = await transaction.get(callerRef);
        if (!callerDoc.exists) {
            throw new https_1.HttpsError("not-found", "User not found");
        }
        const callerData = callerDoc.data();
        if (callerData.role !== types_1.UserRole.SENIOR) {
            throw new https_1.HttpsError("permission-denied", "Only seniors can unlink from guardian");
        }
        linkedGuardianId = callerData.linkedGuardianId || "";
        if (!linkedGuardianId) {
            throw new https_1.HttpsError("failed-precondition", "No guardian linked");
        }
        const guardianRef = db.collection("users").doc(linkedGuardianId);
        transaction.update(callerRef, {
            linkedGuardianId: null,
            updatedAt: firestore_1.FieldValue.serverTimestamp()
        });
        transaction.update(guardianRef, {
            linkedSeniorIds: firestore_1.FieldValue.arrayRemove(auth.uid),
            updatedAt: firestore_1.FieldValue.serverTimestamp()
        });
    });
    if (linkedGuardianId) {
        await (0, audit_1.createAuditLog)({
            eventType: types_1.AuditEventType.ACCOUNT_UNLINKED,
            actorId: auth.uid,
            targetId: linkedGuardianId,
            metadata: { reason: "User requested unlink" }
        });
    }
    return { success: true };
});
//# sourceMappingURL=linkAccounts.js.map