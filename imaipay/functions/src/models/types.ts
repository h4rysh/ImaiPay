/**
 * ImaiPay — Core type definitions for the backend.
 * All monetary values are stored as integer paise (1 INR = 100 paise).
 */

import { Timestamp } from "firebase-admin/firestore";

// ─── Transaction State Machine ──────────────────────────────────────────
export enum TransactionStatus {
  CREATED = "CREATED",
  RISK_EVALUATED = "RISK_EVALUATED",
  ESCROWED = "ESCROWED",
  REVIEW_REQUIRED = "REVIEW_REQUIRED",
  APPROVED = "APPROVED",
  DENIED = "DENIED",
  CANCELLED = "CANCELLED",
  SETTLED = "SETTLED",
  FAILED = "FAILED",
}

export enum RiskLevel {
  LOW = "LOW",
  MEDIUM = "MEDIUM",
  HIGH = "HIGH",
  CRITICAL = "CRITICAL",
}

// ─── Ledger Entry Types ─────────────────────────────────────────────────
export enum LedgerEntryType {
  DEBIT = "DEBIT",
  CREDIT = "CREDIT",
  HOLD = "HOLD",
  RELEASE = "RELEASE",
  REFUND = "REFUND",
  SETTLEMENT = "SETTLEMENT",
  TOP_UP = "TOP_UP",
}

// ─── Audit Event Types ──────────────────────────────────────────────────
export enum AuditEventType {
  TRANSFER_CREATED = "TRANSFER_CREATED",
  TRANSFER_CANCELLED = "TRANSFER_CANCELLED",
  TRANSFER_SETTLED = "TRANSFER_SETTLED",
  GUARDIAN_APPROVED = "GUARDIAN_APPROVED",
  GUARDIAN_DENIED = "GUARDIAN_DENIED",
  ACCOUNT_LINKED = "ACCOUNT_LINKED",
  ACCOUNT_UNLINKED = "ACCOUNT_UNLINKED",
  PAIRING_SESSION_CREATED = "PAIRING_SESSION_CREATED",
  TRUSTED_CONTACT_ADDED = "TRUSTED_CONTACT_ADDED",
  TRUSTED_CONTACT_REMOVED = "TRUSTED_CONTACT_REMOVED",
  ESCROW_DELAY_UPDATED = "ESCROW_DELAY_UPDATED",
  DEMO_FUNDS_ADDED = "DEMO_FUNDS_ADDED",
}

// ─── User Role ──────────────────────────────────────────────────────────
export enum UserRole {
  SENIOR = "senior",
  GUARDIAN = "guardian",
}

// ─── Document Interfaces ────────────────────────────────────────────────

export interface UserDoc {
  phoneNumber: string;
  role: UserRole;
  linkedGuardianId: string | null;
  linkedSeniorIds: string[];
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface WalletDoc {
  availableBalancePaise: number;
  heldBalancePaise: number;
  totalBalancePaise: number;
  currency: string;
  updatedAt: Timestamp;
  version: number;
}

export interface LedgerEntry {
  type: LedgerEntryType;
  amountPaise: number;
  balanceAfterPaise: number;
  transactionId: string | null;
  description: string;
  createdAt: Timestamp;
}

export interface TransactionDoc {
  requestId: string;
  senderId: string;
  recipientName: string;
  recipientPhone: string;
  amountPaise: number;
  currency: string;
  status: TransactionStatus;
  riskLevel: RiskLevel | null;
  riskReasons: string[];
  guardianId: string | null;
  escrowExpiresAt: Timestamp | null;
  holdDurationMinutes: number;
  createdAt: Timestamp;
  updatedAt: Timestamp;
  approvedBy: string | null;
  approvedAt: Timestamp | null;
  deniedBy: string | null;
  deniedAt: Timestamp | null;
  cancelledAt: Timestamp | null;
  settledAt: Timestamp | null;
  refundedAt: Timestamp | null;
}

export interface PairingSessionDoc {
  seniorId: string;
  code: string;
  expiresAt: Timestamp;
  used: boolean;
  attempts: number;
  maxAttempts: number;
  createdAt: Timestamp;
}

export interface AuditLogDoc {
  eventType: AuditEventType;
  actorId: string;
  targetId: string | null;
  metadata: Record<string, unknown>;
  createdAt: Timestamp;
}

// ─── Callable Request/Response Interfaces ───────────────────────────────

export interface CreateTransferRequest {
  requestId: string;
  recipientName: string;
  recipientPhone: string;
  amountPaise: number;
}

export interface CreateTransferResponse {
  transactionId: string;
  status: TransactionStatus;
  riskLevel: RiskLevel;
  riskReasons: string[];
  escrowExpiresAt: string | null;
}

export interface CancelTransferRequest {
  transactionId: string;
}

export interface ApproveTransferRequest {
  transactionId: string;
}

export interface DenyTransferRequest {
  transactionId: string;
}

export interface CreatePairingSessionRequest {
  // No input needed — uses caller's UID
}

export interface CreatePairingSessionResponse {
  code: string;
  expiresInSeconds: number;
}

export interface LinkAccountsRequest {
  code: string;
}

export interface AddDemoFundsRequest {
  amountPaise: number;
}

export interface ModifyTrustedContactsRequest {
  seniorId: string;
  phone: string;
  action: "add" | "remove";
}

export interface UpdateEscrowDelayRequest {
  seniorId: string;
  minutes: number;
}

// Valid escrow delay options in minutes
export const VALID_ESCROW_DELAYS = [5, 15, 30, 60, 1440] as const;

// Maximum demo funds per top-up (₹10,000)
export const MAX_DEMO_TOP_UP_PAISE = 1000000;

// Maximum single transfer (₹50,000)
export const MAX_TRANSFER_PAISE = 5000000;

// Default escrow delay in minutes
export const DEFAULT_ESCROW_DELAY_MINUTES = 5;

// Pairing session expiry in seconds (10 minutes)
export const PAIRING_SESSION_EXPIRY_SECONDS = 600;

// Maximum pairing attempts
export const MAX_PAIRING_ATTEMPTS = 5;
