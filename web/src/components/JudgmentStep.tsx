"use client";

import { useEffect, useState } from "react";
import type { Decision, RiskAnalyzeResponse, VerificationSession } from "@/types";
import { analyzeVerification } from "@/lib/api";

interface JudgmentStepProps {
  session: VerificationSession;
  onComplete: (decision: Decision, rationale: string) => void;
  onBack: () => void;
}

const decisions: { value: Decision; label: string; desc: string }[] = [
  { value: "USE", label: "Use", desc: "그대로 사용" },
  { value: "FIX", label: "Fix", desc: "수정 후 사용" },
  { value: "IGNORE", label: "Ignore", desc: "사용하지 않음" },
];

export function JudgmentStep({ session, onComplete, onBack }: JudgmentStepProps) {
  const [selected, setSelected] = useState<Decision | null>(null);
  const [note, setNote] = useState("");
  const [analysis, setAnalysis] = useState<RiskAnalyzeResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const data = await analyzeVerification(session.id);
        if (!cancelled) setAnalysis(data);
      } catch (err) {
        if (!cancelled) {
          setError(err instanceof Error ? err.message : "리스크 분석에 실패했습니다.");
        }
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [session.id]);

  const risks = analysis?.risks ?? [];

  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-2xl font-bold">3. 판단 수행</h2>
        <p className="mt-1 text-[var(--muted)]">
          AI 리스크 분석 결과를 검토하고 Use / Fix / Ignore 중 하나를 선택하세요.
        </p>
      </div>

      {loading && <p className="text-[var(--muted)]">리스크 분석 중…</p>}
      {error && (
        <p className="rounded-lg border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-700">
          {error}
        </p>
      )}

      {analysis?.explanation && (
        <div className="rounded-xl border border-[var(--border)] bg-[var(--card)] p-4 text-sm text-[var(--muted)]">
          {analysis.explanation}
        </div>
      )}

      {!loading && !error && risks.length > 0 ? (
        <ul className="space-y-3">
          {risks.map((risk) => (
            <li
              key={risk.id}
              className="rounded-xl border border-[var(--border)] bg-[var(--card)] p-4"
            >
              <div className="flex items-center gap-2">
                <span
                  className={`rounded px-2 py-0.5 text-xs font-bold ${
                    risk.severity === "HIGH" || risk.severity === "CRITICAL"
                      ? "bg-red-100 text-red-800"
                      : risk.severity === "MEDIUM"
                        ? "bg-amber-100 text-amber-800"
                        : "bg-slate-100 text-slate-700"
                  }`}
                >
                  {risk.severity}
                </span>
                <span className="font-semibold">{risk.title}</span>
              </div>
              <p className="mt-2 text-sm text-[var(--muted)]">{risk.description}</p>
              {risk.sourceUrl && (
                <a
                  href={risk.sourceUrl}
                  target="_blank"
                  rel="noreferrer"
                  className="mt-2 inline-block text-xs text-[var(--primary)] underline"
                >
                  Evidence 보기
                </a>
              )}
            </li>
          ))}
        </ul>
      ) : null}

      {!loading && !error && risks.length === 0 && (
        <p className="text-sm text-[var(--muted)]">
          확인된 취약점 evidence가 없습니다. 이는 코드가 안전하다는 의미가 아니며, reviewer 판단이
          필요합니다.
        </p>
      )}

      <div className="grid gap-3 sm:grid-cols-3">
        {decisions.map((d) => (
          <button
            key={d.value}
            type="button"
            onClick={() => setSelected(d.value)}
            className={`rounded-xl border-2 p-4 text-left transition-colors ${
              selected === d.value
                ? "border-[var(--primary)] bg-[var(--primary)]/10"
                : "border-[var(--border)] bg-[var(--card)]"
            }`}
          >
            <p className="font-bold">{d.label}</p>
            <p className="mt-1 text-sm text-[var(--muted)]">{d.desc}</p>
          </button>
        ))}
      </div>

      <label className="block space-y-2">
        <span className="text-sm font-medium">추가 판단 근거 (선택)</span>
        <textarea
          className="h-24 w-full rounded-lg border border-[var(--border)] bg-[var(--card)] px-3 py-2"
          value={note}
          onChange={(e) => setNote(e.target.value)}
          placeholder="팀 기준에 맞는 이유를 적어주세요."
        />
      </label>

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
          disabled={!selected || loading || !!error}
          onClick={() => selected && onComplete(selected, note)}
          className="rounded-lg bg-[var(--primary)] px-6 py-2.5 font-semibold text-[var(--primary-foreground)] disabled:opacity-50"
        >
          판단 완료
        </button>
      </div>
    </div>
  );
}
