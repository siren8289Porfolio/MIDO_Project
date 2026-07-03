import type { InputType, NextAction, RiskItem, VerificationSession, WorkContext } from "@/types";

/** nginx /mido/api/ → mido-app */
const base = "/mido/api/verifications";

export interface CreateManualPayload {
  inputType: InputType;
  inputMethod: string;
  rawInput?: string;
  code?: string;
  repoUrl?: string;
  commitHash?: string;
  prNumber?: number;
}

export interface CreateManualResponse {
  id: string;
  status: string;
  nextAction: NextAction;
}

async function handleResponse<T>(res: Response): Promise<T> {
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `Request failed (${res.status})`);
  }
  return res.json() as Promise<T>;
}

export async function createVerification(
  payload: CreateManualPayload
): Promise<CreateManualResponse> {
  const res = await fetch(`${base}/manual`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  return handleResponse<CreateManualResponse>(res);
}

export async function uploadFile(verificationId: string, file: File): Promise<void> {
  const form = new FormData();
  form.append("file", file);
  const res = await fetch(`${base}/${verificationId}/upload`, {
    method: "POST",
    body: form,
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(text || `Upload failed (${res.status})`);
  }
}

export async function getWorkContext(verificationId: string): Promise<WorkContext> {
  const res = await fetch(`${base}/${verificationId}/context`);
  return handleResponse<WorkContext>(res);
}

/** MVP-2 전까지 프론트 목 데이터 */
export function mockRisks(code: string): RiskItem[] {
  if (!code.length) return [];
  return [
    {
      id: "r1",
      severity: "MEDIUM",
      title: "팀 네이밍 컨벤션 확인 필요",
      description: "변수명이 팀 camelCase 기준과 다를 수 있습니다.",
    },
    {
      id: "r2",
      severity: "LOW",
      title: "예외 처리 누락 가능성",
      description: "외부 API 호출 구간에 try-catch가 없을 수 있습니다.",
    },
  ];
}

export function buildSession(
  response: CreateManualResponse,
  partial: Partial<VerificationSession>
): VerificationSession {
  return {
    id: response.id,
    status: response.status,
    nextAction: response.nextAction,
    inputType: partial.inputType ?? "PASTE",
    ...partial,
  };
}
