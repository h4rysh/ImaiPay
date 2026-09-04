import { Transaction } from "firebase-admin/firestore";
import { WalletDoc, LedgerEntry } from "../models/types";
export declare function getOrCreateWallet(txn: Transaction, uid: string): Promise<WalletDoc & {
    ref: FirebaseFirestore.DocumentReference;
}>;
export declare function debitAndHold(txn: Transaction, walletRef: FirebaseFirestore.DocumentReference, wallet: WalletDoc, amountPaise: number): void;
export declare function releaseHoldAndRefund(txn: Transaction, walletRef: FirebaseFirestore.DocumentReference, wallet: WalletDoc, amountPaise: number): void;
export declare function settleHold(txn: Transaction, walletRef: FirebaseFirestore.DocumentReference, wallet: WalletDoc, amountPaise: number): void;
export declare function creditWallet(txn: Transaction, walletRef: FirebaseFirestore.DocumentReference, wallet: WalletDoc, amountPaise: number): void;
export declare function addLedgerEntry(txn: Transaction, uid: string, entry: Omit<LedgerEntry, 'createdAt'>): void;
//# sourceMappingURL=wallet.d.ts.map