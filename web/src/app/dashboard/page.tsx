"use client";

import { useEffect, useState } from "react";
import { BarChart3, Shield } from "lucide-react";
import { getDailyMetrics } from "@/lib/api";
import { SAMPLE_DAILY_METRICS } from "@/lib/sampleMetrics";
import type { DailyProductMetric } from "@/types";
import { DailyMetricsBarChart, DailyMetricsSummaryTable } from "@/components/DailyMetricsBarChart";

/**
 * DA-05 "Key Insights & Dashboard" 라이브 데이터 소스.
 * GET /api/dashboard/daily-metrics (mart_daily_product_metrics 기반) 를 그대로 시각화한다.
 *
 * 실사용 verification 이벤트가 아직 없거나(빈 배열) 백엔드에 연결할 수 없을 때는
 * 화면 레이아웃 확인용 샘플 데이터로 폴백하고, 그 사실을 배지로 명확히 표시한다.
 */
export default function DashboardPage() {
  const [data, setData] = useState<DailyProductMetric[] | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [isSample, setIsSample] = useState(false);

  useEffect(() => {
    getDailyMetrics(30)
      .then((rows) => {
        if (rows.length === 0) {
          setData(SAMPLE_DAILY_METRICS);
          setIsSample(true);
        } else {
          setData(rows);
        }
      })
      .catch((err: unknown) => {
        setError(err instanceof Error ? err.message : "대시보드 데이터를 불러오지 못했습니다.");
        setData(SAMPLE_DAILY_METRICS);
        setIsSample(true);
      });
  }, []);

  return (
    <div className="min-h-screen bg-[var(--background)] text-[var(--foreground)]">
      <header className="border-b border-[var(--border)] bg-[var(--background)]/90 backdrop-blur">
        <div className="mx-auto flex max-w-4xl items-center gap-3 px-4 py-4 sm:px-6">
          <div className="rounded-xl bg-[var(--primary)] p-2 text-[var(--primary-foreground)]">
            <Shield className="h-6 w-6" />
          </div>
          <div>
            <h1 className="text-xl font-bold">MIDO Product Analytics</h1>
            <p className="text-xs text-[var(--muted)]">
              mart_daily_product_metrics · M-001~M-004 일별 추이
            </p>
          </div>
          {isSample && (
            <span className="ml-auto rounded-full border border-amber-400/60 bg-amber-400/10 px-3 py-1 text-xs font-medium text-amber-600">
              샘플 데이터
            </span>
          )}
        </div>
      </header>

      <main className="mx-auto max-w-4xl space-y-6 px-4 py-8 sm:px-6">
        {isSample && (
          <div className="rounded-lg border border-amber-400/40 bg-amber-400/5 p-4 text-sm text-[var(--muted)]">
            {error
              ? `백엔드에 연결하지 못해 샘플 데이터를 표시합니다 (${error}).`
              : "아직 실사용 verification 이벤트가 충분히 쌓이지 않아 레이아웃 확인용 샘플 데이터를 표시합니다."}
            {" "}실제 데이터가 쌓이면 자동으로 대체됩니다.
          </div>
        )}

        <section className="rounded-lg border border-[var(--border)] bg-[var(--card)] p-4">
          <h2 className="mb-3 flex items-center gap-2 text-sm font-semibold">
            <BarChart3 className="h-4 w-4" /> 일별 verification 시작 건수
          </h2>
          {data ? (
            <DailyMetricsBarChart data={data} />
          ) : (
            !error && <p className="text-sm text-[var(--muted)]">불러오는 중...</p>
          )}
        </section>

        <section className="rounded-lg border border-[var(--border)] bg-[var(--card)] p-4">
          <h2 className="mb-3 text-sm font-semibold">일별 지표 상세</h2>
          {data && data.length > 0 ? (
            <DailyMetricsSummaryTable data={data} />
          ) : (
            !error && data && (
              <p className="text-sm text-[var(--muted)]">
                아직 표시할 데이터가 없습니다.
              </p>
            )
          )}
        </section>
      </main>
    </div>
  );
}
