import { Timestamp, FieldValue } from "firebase-admin/firestore";

import * as admin from 'firebase-admin';
import { AuditEventType } from '../models/types';

export interface CreateAuditLogParams {
  eventType: AuditEventType;
  actorId: string;
  targetId: string | null;
  metadata: Record<string, unknown>;
}

export async function createAuditLog(params: CreateAuditLogParams): Promise<void> {
  const db = admin.firestore();
  
  await db.collection('auditLogs').add({
    eventType: params.eventType,
    actorId: params.actorId,
    targetId: params.targetId,
    metadata: params.metadata,
    createdAt: FieldValue.serverTimestamp(),
  });
}
