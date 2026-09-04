import { RiskLevel } from '../models/types';
export interface EvaluateRiskParams {
    amountPaise: number;
    recipientPhone: string;
    trustedContacts: string[];
    hasGuardian: boolean;
    isCallActive: boolean;
}
export declare function evaluateRisk(params: EvaluateRiskParams): {
    riskLevel: RiskLevel;
    riskReasons: string[];
};
export declare function requiresGuardianReview(riskLevel: RiskLevel, hasGuardian: boolean): boolean;
//# sourceMappingURL=risk.d.ts.map