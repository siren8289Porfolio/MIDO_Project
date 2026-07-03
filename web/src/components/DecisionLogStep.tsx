"use client";

import type { DecisionRecord, VerificationSession } from "@/types";

interface DecisionLogStepProps {
  session: VerificationSession;
  record: DecisionRecord;
  onRestart: () => void;
}

export function DecisionLogStep({ session, record, onRestart }: DecisionLogStepProps) {
  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-2xl font-bold">4. 판단 기록</h2>
        <p className="mt-1 text-[var(--muted)]">판단이 기록되었습니다. (MVP-2에서 서버 저장 예정)</p>
      </div>

      <div className="rounded-xl border border-emerald-500/30 bg-emerald-500/10 p-6">
        <p className="text-sm font-medium text-emerald-800 dark:text-emerald-200">판단 완료</p>
        <p className="mt-2 text-3xl font-bold">{record.decision}</p>
        <p className="mt-2 text-sm text-[var(--muted)]">
          {new Date(record.decidedAt).toLocaleString("ko-KR")}
        </p>
      </div>

      <dl className="space-y-3 rounded-xl border border-[var(--border)] bg-[var(--card)] p-4">
        <div>
          <dt className="text-xs text-[var(--muted)]">Verification ID</dt>
          <dd className="font-mono text-sm">{session.id}</dd>
        </div>
        {session.taskTitle && (
          <div>
            <dt className="text-xs text-[var(--muted)]">작업</dt>
            <dd>{session.taskTitle}</dd>
          </div>
        )}
        {record.rationale && (
          <div>
            <dt className="text-xs text-[var(--muted)]">판단 근거</dt>
            <dd className="text-sm">{record.rationale}</dd>
          </div>
        )}
      </dl>

      <button
        type="button"
        onClick={onRestart}
        className="rounded-lg bg-[var(--primary)] px-6 py-2.5 font-semibold text-[var(--primary-foreground)]"
      >
        새 검토 시작
      </button>
    </div>
  );
}
