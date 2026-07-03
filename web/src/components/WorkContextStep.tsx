"use client";

import { useEffect, useState } from "react";
import type { VerificationSession, WorkContext } from "@/types";
import { getWorkContext } from "@/lib/api";

interface WorkContextStepProps {
  session: VerificationSession;
  onNext: () => void;
  onBack: () => void;
}

export function WorkContextStep({ session, onNext, onBack }: WorkContextStepProps) {
  const [context, setContext] = useState<WorkContext | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const data = await getWorkContext(session.id);
        if (!cancelled) setContext(data);
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "맥락 조회에 실패했습니다.");
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [session.id]);

  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-2xl font-bold">2. 작업 맥락</h2>
        <p className="mt-1 text-[var(--muted)]">판단에 필요한 맥락을 확인합니다.</p>
      </div>

      {session.taskTitle && (
        <div className="rounded-xl border border-[var(--border)] bg-[var(--card)] p-4">
          <p className="text-xs font-medium uppercase text-[var(--muted)]">작업</p>
          <p className="mt-1 font-semibold">{session.taskTitle}</p>
          {session.purpose && <p className="mt-2 text-sm text-[var(--muted)]">{session.purpose}</p>}
        </div>
      )}

      {loading && <p className="text-[var(--muted)]">맥락 불러오는 중…</p>}
      {error && (
        <p className="rounded-lg border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-700">
          {error}
        </p>
      )}

      {context && (
        <dl className="grid gap-3 rounded-xl border border-[var(--border)] bg-[var(--card)] p-4 sm:grid-cols-2">
          <div>
            <dt className="text-xs text-[var(--muted)]">입력 유형</dt>
            <dd className="font-mono font-medium">{context.contextType}</dd>
          </div>
          {context.repoUrl && (
            <div className="sm:col-span-2">
              <dt className="text-xs text-[var(--muted)]">Repository</dt>
              <dd className="break-all font-mono text-sm">{context.repoUrl}</dd>
            </div>
          )}
          {context.commitHash && (
            <div>
              <dt className="text-xs text-[var(--muted)]">Commit</dt>
              <dd className="font-mono text-sm">{context.commitHash}</dd>
            </div>
          )}
          {context.prNumber != null && (
            <div>
              <dt className="text-xs text-[var(--muted)]">PR</dt>
              <dd className="font-mono">#{context.prNumber}</dd>
            </div>
          )}
          {context.fileName && (
            <div>
              <dt className="text-xs text-[var(--muted)]">파일</dt>
              <dd className="font-mono text-sm">{context.fileName}</dd>
            </div>
          )}
        </dl>
      )}

      <div className="flex gap-3">
        <button
          type="button"
          onClick={onBack}
          className="rounded-lg border border-[var(--border)] px-5 py-2.5 font-medium"
        >
          이전
        </button>
        <button
          type="button"
          onClick={onNext}
          disabled={loading || !!error}
          className="rounded-lg bg-[var(--primary)] px-6 py-2.5 font-semibold text-[var(--primary-foreground)] disabled:opacity-50"
        >
          다음: 판단 수행
        </button>
      </div>
    </div>
  );
}
