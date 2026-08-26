import type { DailyProductMetric } from "@/types";

/**
 * mart_daily_product_metrics 스키마와 동일한 형태의 예시 데이터.
 *
 * 실사용 verification 이벤트가 쌓이기 전까지 대시보드가 빈 화면으로 보이지 않도록
 * DashboardPage에서 폴백용으로만 사용한다. 실제 값이 하나라도 오면 이 데이터는 쓰이지 않는다.
 */
export const SAMPLE_DAILY_METRICS: DailyProductMetric[] = [
  { metricDate: "2026-08-13", verificationStartedCount: 18, verificationDoneCount: 12, decisionLogCount: 9, fixDecisionCount: 3, reworkCount: 2, m001DecisionLogRate: 0.75, m002AvgApprovalSeconds: 610, m003ReworkRate: 0.1667, m004CompletionRate: 0.6667, m005AuditManualTimeReductionRate: null },
  { metricDate: "2026-08-14", verificationStartedCount: 22, verificationDoneCount: 15, decisionLogCount: 11, fixDecisionCount: 4, reworkCount: 3, m001DecisionLogRate: 0.7333, m002AvgApprovalSeconds: 590, m003ReworkRate: 0.2, m004CompletionRate: 0.6818, m005AuditManualTimeReductionRate: null },
  { metricDate: "2026-08-15", verificationStartedCount: 15, verificationDoneCount: 10, decisionLogCount: 8, fixDecisionCount: 2, reworkCount: 1, m001DecisionLogRate: 0.8, m002AvgApprovalSeconds: 545, m003ReworkRate: 0.1, m004CompletionRate: 0.6667, m005AuditManualTimeReductionRate: null },
  { metricDate: "2026-08-16", verificationStartedCount: 9, verificationDoneCount: 7, decisionLogCount: 6, fixDecisionCount: 1, reworkCount: 0, m001DecisionLogRate: 0.8571, m002AvgApprovalSeconds: 480, m003ReworkRate: 0, m004CompletionRate: 0.7778, m005AuditManualTimeReductionRate: null },
  { metricDate: "2026-08-17", verificationStartedCount: 26, verificationDoneCount: 19, decisionLogCount: 14, fixDecisionCount: 6, reworkCount: 5, m001DecisionLogRate: 0.7368, m002AvgApprovalSeconds: 705, m003ReworkRate: 0.2632, m004CompletionRate: 0.7308, m005AuditManualTimeReductionRate: null },
  { metricDate: "2026-08-18", verificationStartedCount: 24, verificationDoneCount: 18, decisionLogCount: 15, fixDecisionCount: 5, reworkCount: 3, m001DecisionLogRate: 0.8333, m002AvgApprovalSeconds: 630, m003ReworkRate: 0.1667, m004CompletionRate: 0.75, m005AuditManualTimeReductionRate: null },
  { metricDate: "2026-08-19", verificationStartedCount: 20, verificationDoneCount: 16, decisionLogCount: 13, fixDecisionCount: 4, reworkCount: 2, m001DecisionLogRate: 0.8125, m002AvgApprovalSeconds: 560, m003ReworkRate: 0.125, m004CompletionRate: 0.8, m005AuditManualTimeReductionRate: null },
  { metricDate: "2026-08-20", verificationStartedCount: 28, verificationDoneCount: 21, decisionLogCount: 17, fixDecisionCount: 7, reworkCount: 6, m001DecisionLogRate: 0.8095, m002AvgApprovalSeconds: 690, m003ReworkRate: 0.2857, m004CompletionRate: 0.75, m005AuditManualTimeReductionRate: null },
  { metricDate: "2026-08-21", verificationStartedCount: 19, verificationDoneCount: 15, decisionLogCount: 12, fixDecisionCount: 3, reworkCount: 1, m001DecisionLogRate: 0.8, m002AvgApprovalSeconds: 505, m003ReworkRate: 0.0667, m004CompletionRate: 0.7895, m005AuditManualTimeReductionRate: null },
  { metricDate: "2026-08-22", verificationStartedCount: 12, verificationDoneCount: 9, decisionLogCount: 8, fixDecisionCount: 2, reworkCount: 1, m001DecisionLogRate: 0.8889, m002AvgApprovalSeconds: 470, m003ReworkRate: 0.1111, m004CompletionRate: 0.75, m005AuditManualTimeReductionRate: null },
  { metricDate: "2026-08-23", verificationStartedCount: 30, verificationDoneCount: 23, decisionLogCount: 19, fixDecisionCount: 8, reworkCount: 7, m001DecisionLogRate: 0.8261, m002AvgApprovalSeconds: 715, m003ReworkRate: 0.3043, m004CompletionRate: 0.7667, m005AuditManualTimeReductionRate: null },
  { metricDate: "2026-08-24", verificationStartedCount: 25, verificationDoneCount: 20, decisionLogCount: 17, fixDecisionCount: 5, reworkCount: 3, m001DecisionLogRate: 0.85, m002AvgApprovalSeconds: 600, m003ReworkRate: 0.15, m004CompletionRate: 0.8, m005AuditManualTimeReductionRate: null },
  { metricDate: "2026-08-25", verificationStartedCount: 27, verificationDoneCount: 22, decisionLogCount: 19, fixDecisionCount: 6, reworkCount: 3, m001DecisionLogRate: 0.8636, m002AvgApprovalSeconds: 555, m003ReworkRate: 0.1364, m004CompletionRate: 0.8148, m005AuditManualTimeReductionRate: null },
  { metricDate: "2026-08-26", verificationStartedCount: 16, verificationDoneCount: 13, decisionLogCount: 12, fixDecisionCount: 3, reworkCount: 1, m001DecisionLogRate: 0.9231, m002AvgApprovalSeconds: 510, m003ReworkRate: 0.0769, m004CompletionRate: 0.8125, m005AuditManualTimeReductionRate: null },
];
