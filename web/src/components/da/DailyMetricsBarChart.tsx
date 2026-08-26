"use client";

import type { DailyProductMetric } from "@/types";

function formatPercent(value: number | null): string {
  if (value === null || Number.isNaN(value)) return "—";
  return `${(value * 100).toFixed(1)}%`;
}

function formatSeconds(value: number | null): string {
  if (value === null || Number.isNaN(value)) return "—";
  return `${Math.round(value)}s`;
}

/**
 * 의존성 추가 없이 순수 CSS로 그리는 막대 차트.
 * DA-05 "Key Insights & Dashboard" — verification_started_count 기준 최근 N일 추이.
 */
export function DailyMetricsBarChart({ data }: { data: DailyProductMetric[] }) {
  if (data.length === 0) {
    return (
      <p className="text-sm text-[var(--muted)]">
        아직 집계된 verification 이벤트가 없습니다. 실제 사용 데이터가 쌓이면 이 영역에
        일별 추이가 표시됩니다.
      </p>
    );
  }

  const sorted = [...data].sort((a, b) => a.metricDate.localeCompare(b.metricDate));
  const max = Math.max(...sorted.map((d) => d.verificationStartedCount), 1);

  return (
    <div className="space-y-2">
      {sorted.map((row) => (
        <div key={row.metricDate} className="flex items-center gap-3 text-sm">
          <span className="w-24 shrink-0 text-[var(--muted)]">{row.metricDate}</span>
          <div className="h-4 flex-1 rounded bg-[var(--border)]">
            <div
              className="h-4 rounded bg-[var(--primary)]"
              style={{ width: `${(row.verificationStartedCount / max) * 100}%` }}
            />
          </div>
          <span className="w-10 shrink-0 text-right tabular-nums">
            {row.verificationStartedCount}
          </span>
        </div>
      ))}
    </div>
  );
}

export function DailyMetricsSummaryTable({ data }: { data: DailyProductMetric[] }) {
  if (data.length === 0) return null;

  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[640px] text-left text-sm">
        <thead>
          <tr className="border-b border-[var(--border)] text-[var(--muted)]">
            <th className="py-2 pr-4">날짜</th>
            <th className="py-2 pr-4">시작</th>
            <th className="py-2 pr-4">완료</th>
            <th className="py-2 pr-4">M-001 DecisionLog율</th>
            <th className="py-2 pr-4">M-002 평균 승인시간</th>
            <th className="py-2 pr-4">M-003 재작업률</th>
            <th className="py-2 pr-4">M-004 완료율</th>
          </tr>
        </thead>
        <tbody>
          {data.map((row) => (
            <tr key={row.metricDate} className="border-b border-[var(--border)]/60">
              <td className="py-2 pr-4">{row.metricDate}</td>
              <td className="py-2 pr-4">{row.verificationStartedCount}</td>
              <td className="py-2 pr-4">{row.verificationDoneCount}</td>
              <td className="py-2 pr-4">{formatPercent(row.m001DecisionLogRate)}</td>
              <td className="py-2 pr-4">{formatSeconds(row.m002AvgApprovalSeconds)}</td>
              <td className="py-2 pr-4">{formatPercent(row.m003ReworkRate)}</td>
              <td className="py-2 pr-4">{formatPercent(row.m004CompletionRate)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
