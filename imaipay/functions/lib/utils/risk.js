"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.evaluateRisk = evaluateRisk;
exports.requiresGuardianReview = requiresGuardianReview;
const types_1 = require("../models/types");
function evaluateRisk(params) {
    let riskLevel = types_1.RiskLevel.LOW;
    const riskReasons = [];
    if (params.isCallActive) {
        riskReasons.push('active_phone_call');
        riskLevel = types_1.RiskLevel.CRITICAL;
    }
    if (!params.trustedContacts.includes(params.recipientPhone)) {
        riskReasons.push('untrusted_recipient');
        if (riskLevel === types_1.RiskLevel.LOW) {
            riskLevel = types_1.RiskLevel.MEDIUM;
        }
    }
    if (params.amountPaise > 2000000) { // ₹20,000
        riskReasons.push('very_high_value_transfer');
        if (riskLevel !== types_1.RiskLevel.CRITICAL) {
            riskLevel = types_1.RiskLevel.HIGH;
        }
    }
    else if (params.amountPaise > 500000) { // ₹5,000
        riskReasons.push('high_value_transfer');
        if (riskLevel === types_1.RiskLevel.LOW) {
            riskLevel = types_1.RiskLevel.MEDIUM;
        }
    }
    return { riskLevel, riskReasons };
}
function requiresGuardianReview(riskLevel, hasGuardian) {
    if (!hasGuardian)
        return false;
    return riskLevel === types_1.RiskLevel.MEDIUM || riskLevel === types_1.RiskLevel.HIGH || riskLevel === types_1.RiskLevel.CRITICAL;
}
//# sourceMappingURL=risk.js.map