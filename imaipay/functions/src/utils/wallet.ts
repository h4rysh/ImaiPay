import * as admin from "firebase-admin";
import { Transaction, Timestamp, FieldValue } from "firebase-admin/firestore";
import { WalletDoc, LedgerEntry } from "../models/types";

export async function getOrCreateWallet(
  txn: Transaction,
  uid: string
): Promise<WalletDoc & { ref: FirebaseFirestore.DocumentReference }> {
  const db = admin.firestore();
  const walletRef = db.collection('wallets').doc(uid);
  const walletDoc = await txn.get(walletRef);

  if (!walletDoc.exists) {
    const newWallet: WalletDoc = {
      availableBalancePaise: 0,
      heldBalancePaise: 0,
      totalBalancePaise: 0,
      currency: "INR",
      version: 1,
      updatedAt: FieldValue.serverTimestamp() as any,
    };
    txn.set(walletRef, newWallet);
    return { ...newWallet, ref: walletRef };
  }

  return { ...(walletDoc.data() as WalletDoc), ref: walletRef };
}

export function debitAndHold(
  txn: Transaction,
  walletRef: FirebaseFirestore.DocumentReference,
  wallet: WalletDoc,
  amountPaise: number
): void {
  if (wallet.availableBalancePaise < amountPaise) {
    throw new Error('Insufficient available balance');
  }

  txn.update(walletRef, {
    availableBalancePaise: FieldValue.increment(-amountPaise),
    heldBalancePaise: FieldValue.increment(amountPaise),
    version: FieldValue.increment(1),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

export function releaseHoldAndRefund(
  txn: Transaction,
  walletRef: FirebaseFirestore.DocumentReference,
  wallet: WalletDoc,
  amountPaise: number
): void {
  txn.update(walletRef, {
    availableBalancePaise: FieldValue.increment(amountPaise),
    heldBalancePaise: FieldValue.increment(-amountPaise),
    version: FieldValue.increment(1),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

export function settleHold(
  txn: Transaction,
  walletRef: FirebaseFirestore.DocumentReference,
  wallet: WalletDoc,
  amountPaise: number
): void {
  txn.update(walletRef, {
    heldBalancePaise: FieldValue.increment(-amountPaise),
    version: FieldValue.increment(1),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

export function creditWallet(
  txn: Transaction,
  walletRef: FirebaseFirestore.DocumentReference,
  wallet: WalletDoc,
  amountPaise: number
): void {
  txn.update(walletRef, {
    availableBalancePaise: FieldValue.increment(amountPaise),
    version: FieldValue.increment(1),
    updatedAt: FieldValue.serverTimestamp(),
  });
}

export function addLedgerEntry(
  txn: Transaction,
  uid: string,
  entry: Omit<LedgerEntry, 'createdAt'>
): void {
  const db = admin.firestore();
  const ledgerRef = db.collection('wallets').doc(uid).collection('ledger').doc();
  txn.set(ledgerRef, {
    ...entry,
    createdAt: FieldValue.serverTimestamp(),
  });
}
