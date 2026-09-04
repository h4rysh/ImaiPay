"use strict";
/**
 * ImaiPay — Core type definitions for the backend.
 * All monetary values are stored as integer paise (1 INR = 100 paise).
 */
Object.defineProperty(exports, "__esModule", { value: true });
exports.MAX_PAIRING_ATTEMPTS = exports.PAIRING_SESSION_EXPIRY_SECONDS = exports.DEFAULT_ESCROW_DELAY_MINUTES = exports.MAX_TRANSFER_PAISE = exports.MAX_DEMO_TOP_UP_PAISE = exports.VALID_ESCROW_DELAYS = exports.UserRole = exports.AuditEventType = exports.LedgerEntryType = exports.RiskLevel = exports.TransactionStatus = void 0;
// ─── Transaction State Machine ──────────────────────────────────────────
var TransactionStatus;
(function (TransactionStatus) {
    TransactionStatus["CREATED"] = "CREATED";
    TransactionStatus["RISK_EVALUATED"] = "RISK_EVALUATED";
    TransactionStatus["ESCROWED"] = "ESCROWED";
    TransactionStatus["REVIEW_REQUIRED"] = "REVIEW_REQUIRED";
    TransactionStatus["APPROVED"] = "APPROVED";
    TransactionStatus["DENIED"] = "DENIED";
    TransactionStatus["CANCELLED"] = "CANCELLED";
    TransactionStatus["SETTLED"] = "SETTLED";
    TransactionStatus["FAILED"] = "FAILED";
})(TransactionStatus || (exports.TransactionStatus = TransactionStatus = {}));
var RiskLevel;
(function (RiskLevel) {
    RiskLevel["LOW"] = "LOW";
    RiskLevel["MEDIUM"] = "MEDIUM";
    RiskLevel["HIGH"] = "HIGH";
    RiskLevel["CRITICAL"] = "CRITICAL";
})(RiskLevel || (exports.RiskLevel = RiskLevel = {}));
// ─── Ledger Entry Types ─────────────────────────────────────────────────
var LedgerEntryType;
(function (LedgerEntryType) {
    LedgerEntryType["DEBIT"] = "DEBIT";
    LedgerEntryType["CREDIT"] = "CREDIT";
    LedgerEntryType["HOLD"] = "HOLD";
    LedgerEntryType["RELEASE"] = "RELEASE";
    LedgerEntryType["REFUND"] = "REFUND";
    LedgerEntryType["SETTLEMENT"] = "SETTLEMENT";
    LedgerEntryType["TOP_UP"] = "TOP_UP";
})(LedgerEntryType || (exports.LedgerEntryType = LedgerEntryType = {}));
// ─── Audit Event Types ──────────────────────────────────────────────────
var AuditEventType;
(function (AuditEventType) {
    AuditEventType["TRANSFER_CREATED"] = "TRANSFER_CREATED";
    AuditEventType["TRANSFER_CANCELLED"] = "TRANSFER_CANCELLED";
    AuditEventType["TRANSFER_SETTLED"] = "TRANSFER_SETTLED";
    AuditEventType["GUARDIAN_APPROVED"] = "GUARDIAN_APPROVED";
    AuditEventType["GUARDIAN_DENIED"] = "GUARDIAN_DENIED";
    AuditEventType["ACCOUNT_LINKED"] = "ACCOUNT_LINKED";
    AuditEventType["ACCOUNT_UNLINKED"] = "ACCOUNT_UNLINKED";
    AuditEventType["PAIRING_SESSION_CREATED"] = "PAIRING_SESSION_CREATED";
    AuditEventType["TRUSTED_CONTACT_ADDED"] = "TRUSTED_CONTACT_ADDED";
    AuditEventType["TRUSTED_CONTACT_REMOVED"] = "TRUSTED_CONTACT_REMOVED";
    AuditEventType["ESCROW_DELAY_UPDATED"] = "ESCROW_DELAY_UPDATED";
    AuditEventType["DEMO_FUNDS_ADDED"] = "DEMO_FUNDS_ADDED";
})(AuditEventType || (exports.AuditEventType = AuditEventType = {}));
// ─── User Role ──────────────────────────────────────────────────────────
var UserRole;
(function (UserRole) {
    UserRole["SENIOR"] = "senior";
    UserRole["GUARDIAN"] = "guardian";
})(UserRole || (exports.UserRole = UserRole = {}));
// Valid escrow delay options in minutes
exports.VALID_ESCROW_DELAYS = [5, 15, 30, 60, 1440];
// Maximum demo funds per top-up (₹10,000)
exports.MAX_DEMO_TOP_UP_PAISE = 1000000;
// Maximum single transfer (₹50,000)
exports.MAX_TRANSFER_PAISE = 5000000;
// Default escrow delay in minutes
exports.DEFAULT_ESCROW_DELAY_MINUTES = 5;
// Pairing session expiry in seconds (10 minutes)
exports.PAIRING_SESSION_EXPIRY_SECONDS = 600;
// Maximum pairing attempts
exports.MAX_PAIRING_ATTEMPTS = 5;
//# sourceMappingURL=types.js.map