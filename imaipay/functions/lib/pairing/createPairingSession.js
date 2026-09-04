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
exports.createPairingSession = void 0;
const firestore_1 = require("firebase-admin/firestore");
const https_1 = require("firebase-functions/v2/https");
const admin = __importStar(require("firebase-admin"));
const types_1 = require("../models/types");
const audit_1 = require("../utils/audit");
exports.createPairingSession = (0, https_1.onCall)({ region: "asia-south1" }, async (request) => {
    const { auth } = request;
    if (!auth) {
        throw new https_1.HttpsError("unauthenticated", "User must be authenticated");
    }
    const db = admin.firestore();
    const userRef = db.collection("users").doc(auth.uid);
    const userDoc = await userRef.get();
    if (!userDoc.exists) {
        throw new https_1.HttpsError("not-found", "User not found");
    }
    const userData = userDoc.data();
    if (userData.role !== types_1.UserRole.SENIOR) {
        throw new https_1.HttpsError("permission-denied", "Only seniors can create a pairing session");
    }
    const code = Math.floor(100000 + Math.random() * 900000).toString();
    const expiresAt = firestore_1.Timestamp.fromMillis(Date.now() + types_1.PAIRING_SESSION_EXPIRY_SECONDS * 1000);
    const batch = db.batch();
    // Invalidate old unused sessions
    const oldSessions = await db.collection("pairingSessions")
        .where("seniorId", "==", auth.uid)
        .where("used", "==", false)
        .get();
    oldSessions.docs.forEach((doc) => {
        batch.update(doc.ref, { used: true });
    });
    const sessionRef = db.collection("pairingSessions").doc();
    const sessionData = {
        seniorId: auth.uid,
        code,
        expiresAt,
        used: false,
        attempts: 0,
        maxAttempts: types_1.MAX_PAIRING_ATTEMPTS,
        createdAt: firestore_1.FieldValue.serverTimestamp()
    };
    batch.set(sessionRef, sessionData);
    await batch.commit();
    await (0, audit_1.createAuditLog)({
        eventType: types_1.AuditEventType.PAIRING_SESSION_CREATED,
        actorId: auth.uid,
        targetId: sessionRef.id,
        metadata: { code } // you might not want to log the code in reality, but just following instructions
    });
    return { code, expiresInSeconds: types_1.PAIRING_SESSION_EXPIRY_SECONDS };
});
//# sourceMappingURL=createPairingSession.js.map