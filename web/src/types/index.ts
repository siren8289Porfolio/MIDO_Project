export type InputType = "PASTE" | "FILE" | "COMMIT" | "PR";
export type NextAction = "UPLOAD_FILE" | "VIEW_CONTEXT" | "WAIT";
export type Decision = "USE" | "FIX" | "IGNORE";

export interface VerificationSession {
  id: string;
  status: string;
  nextAction: NextAction;
  taskTitle?: string;
  purpose?: string;
  inputType: InputType;
  code?: string;
  repoUrl?: string;
  commitHash?: string;
  prNumber?: number;
}

export interface WorkContext {
  contextType: string;
  repoUrl?: string | null;
  commitHash?: string | null;
  prNumber?: number | null;
  fileName?: string | null;
  language?: string | null;
  lineCount?: number | null;
  snippet?: string | null;
}

export interface RiskItem {
  id: string;
  severity: "LOW" | "MEDIUM" | "HIGH" | "CRITICAL" | "UNKNOWN";
  title: string;
  description: string;
  cveId?: string | null;
  ghsaId?: string | null;
  packageName?: string | null;
  packageVersion?: string | null;
  source?: string | null;
  sourceUrl?: string | null;
  evidenceStatus?: string | null;
}

export interface RiskAnalyzeResponse {
  analysisRunId: string;
  outputStatus: string;
  confidence: string;
  recommendation: string;
  explanation?: string | null;
  risks: RiskItem[];
}

export interface DecisionRecord {
  decision: Decision;
  rationale: string;
  decidedAt: string;
}
