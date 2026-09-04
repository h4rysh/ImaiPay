import { RiskLevel } from '../models/types';

export interface EvaluateRiskParams {
  amountPaise: number;
  recipientPhone: string;
  trustedContacts: string[];
  hasGuardian: boolean;
  isCallActive: boolean;
}

export function evaluateRisk(params: EvaluateRiskParams): { riskLevel: RiskLevel; riskReasons: string[] } {
  let riskLevel: RiskLevel = RiskLevel.LOW;
  const riskReasons: string[] = [];

  if (params.isCallActive) {
    riskReasons.push('active_phone_call');
    riskLevel = RiskLevel.CRITICAL;
  }

  if (!params.trustedContacts.includes(params.recipientPhone)) {
    riskReasons.push('untrusted_recipient');
    if (riskLevel === RiskLevel.LOW) {
      riskLevel = RiskLevel.MEDIUM;
    }
  }

  if (params.amountPaise > 2000000) { // ₹20,000
    riskReasons.push('very_high_value_transfer');
    if (riskLevel !== RiskLevel.CRITICAL) {
      riskLevel = RiskLevel.HIGH;
    }
  } else if (params.amountPaise > 500000) { // ₹5,000
    riskReasons.push('high_value_transfer');
    if (riskLevel === RiskLevel.LOW) {
      riskLevel = RiskLevel.MEDIUM;
    }
  }

  return { riskLevel, riskReasons };
}

export function requiresGuardianReview(riskLevel: RiskLevel, hasGuardian: boolean): boolean {
  if (!hasGuardian) return false;
  return riskLevel === RiskLevel.MEDIUM || riskLevel === RiskLevel.HIGH || riskLevel === RiskLevel.CRITICAL;
}
