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
exports.getOrCreateWallet = getOrCreateWallet;
exports.debitAndHold = debitAndHold;
exports.releaseHoldAndRefund = releaseHoldAndRefund;
exports.settleHold = settleHold;
exports.creditWallet = creditWallet;
exports.addLedgerEntry = addLedgerEntry;
const admin = __importStar(require("firebase-admin"));
const firestore_1 = require("firebase-admin/firestore");
async function getOrCreateWallet(txn, uid) {
    const db = admin.firestore();
    const walletRef = db.collection('wallets').doc(uid);
    const walletDoc = await txn.get(walletRef);
    if (!walletDoc.exists) {
        const newWallet = {
            availableBalancePaise: 0,
            heldBalancePaise: 0,
            totalBalancePaise: 0,
            currency: "INR",
            version: 1,
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        };
        txn.set(walletRef, newWallet);
        return { ...newWallet, ref: walletRef };
    }
    return { ...walletDoc.data(), ref: walletRef };
}
function debitAndHold(txn, walletRef, wallet, amountPaise) {
    if (wallet.availableBalancePaise < amountPaise) {
        throw new Error('Insufficient available balance');
    }
    txn.update(walletRef, {
        availableBalancePaise: firestore_1.FieldValue.increment(-amountPaise),
        heldBalancePaise: firestore_1.FieldValue.increment(amountPaise),
        version: firestore_1.FieldValue.increment(1),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
}
function releaseHoldAndRefund(txn, walletRef, wallet, amountPaise) {
    txn.update(walletRef, {
        availableBalancePaise: firestore_1.FieldValue.increment(amountPaise),
        heldBalancePaise: firestore_1.FieldValue.increment(-amountPaise),
        version: firestore_1.FieldValue.increment(1),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
}
function settleHold(txn, walletRef, wallet, amountPaise) {
    txn.update(walletRef, {
        heldBalancePaise: firestore_1.FieldValue.increment(-amountPaise),
        version: firestore_1.FieldValue.increment(1),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
}
function creditWallet(txn, walletRef, wallet, amountPaise) {
    txn.update(walletRef, {
        availableBalancePaise: firestore_1.FieldValue.increment(amountPaise),
        version: firestore_1.FieldValue.increment(1),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
}
function addLedgerEntry(txn, uid, entry) {
    const db = admin.firestore();
    const ledgerRef = db.collection('wallets').doc(uid).collection('ledger').doc();
    txn.set(ledgerRef, {
        ...entry,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
    });
}
//# sourceMappingURL=wallet.js.map