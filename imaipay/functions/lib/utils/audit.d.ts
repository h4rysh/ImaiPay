import { AuditEventType } from '../models/types';
export interface CreateAuditLogParams {
    eventType: AuditEventType;
    actorId: string;
    targetId: string | null;
    metadata: Record<string, unknown>;
}
export declare function createAuditLog(params: CreateAuditLogParams): Promise<void>;
//# sourceMappingURL=audit.d.ts.map