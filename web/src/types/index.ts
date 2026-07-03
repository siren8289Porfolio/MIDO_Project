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
  severity: "LOW" | "MEDIUM" | "HIGH";
  title: string;
  description: string;
}

export interface DecisionRecord {
  decision: Decision;
  rationale: string;
  decidedAt: string;
}
