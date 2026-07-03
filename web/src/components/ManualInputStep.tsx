"use client";

import { useState } from "react";
import { Clipboard, Upload, GitBranch, GitPullRequest } from "lucide-react";
import type { InputType, VerificationSession } from "@/types";
import { createVerification, uploadFile } from "@/lib/api";

interface ManualInputStepProps {
  session: VerificationSession | null;
  onComplete: (session: VerificationSession) => void;
}

const methods: { type: InputType; label: string; icon: typeof Clipboard }[] = [
  { type: "PASTE", label: "붙여넣기", icon: Clipboard },
  { type: "FILE", label: "파일", icon: Upload },
  { type: "COMMIT", label: "커밋", icon: GitBranch },
  { type: "PR", label: "PR", icon: GitPullRequest },
];

export function ManualInputStep({ session, onComplete }: ManualInputStepProps) {
  const [inputType, setInputType] = useState<InputType>(session?.inputType ?? "PASTE");
  const [taskTitle, setTaskTitle] = useState(session?.taskTitle ?? "");
  const [purpose, setPurpose] = useState(session?.purpose ?? "");
  const [rawInput, setRawInput] = useState(session?.code ?? "");
  const [file, setFile] = useState<File | null>(null);
  const [repoUrl, setRepoUrl] = useState(session?.repoUrl ?? "");
  const [commitHash, setCommitHash] = useState(session?.commitHash ?? "");
  const [prNumber, setPrNumber] = useState(session?.prNumber?.toString() ?? "");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const inputMethod =
    inputType === "FILE" ? "FILE_UPLOAD" : inputType === "PASTE" ? "TEXTAREA" : inputType;

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const payload = {
        inputType,
        inputMethod,
        rawInput: inputType === "PASTE" ? rawInput : undefined,
        code: inputType === "PASTE" ? rawInput : undefined,
        repoUrl: inputType === "COMMIT" || inputType === "PR" ? repoUrl : undefined,
        commitHash: inputType === "COMMIT" ? commitHash : undefined,
        prNumber: inputType === "PR" ? Number(prNumber) : undefined,
      };

      const res = await createVerification(payload);

      if (inputType === "FILE" && file) {
        await uploadFile(res.id, file);
      }

      onComplete({
        id: res.id,
        status: res.status,
        nextAction: res.nextAction,
        inputType,
        taskTitle,
        purpose,
        code: inputType === "PASTE" ? rawInput : undefined,
        repoUrl: payload.repoUrl,
        commitHash: payload.commitHash,
        prNumber: payload.prNumber,
      });
    } catch (err) {
      setError(err instanceof Error ? err.message : "요청에 실패했습니다.");
    } finally {
      setLoading(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-8">
      <div>
        <h2 className="text-2xl font-bold">1. 판단 대상 입력</h2>
        <p className="mt-1 text-[var(--muted)]">검토할 AI 결과물 또는 코드를 입력하세요.</p>
      </div>

      <div className="grid gap-4 sm:grid-cols-2">
        <label className="block space-y-2">
          <span className="text-sm font-medium">작업 제목</span>
          <input
            className="w-full rounded-lg border border-[var(--border)] bg-[var(--card)] px-3 py-2"
            value={taskTitle}
            onChange={(e) => setTaskTitle(e.target.value)}
            placeholder="예: 사용자 인증 리팩토링"
          />
        </label>
        <label className="block space-y-2 sm:col-span-2">
          <span className="text-sm font-medium">목적 / 배경</span>
          <textarea
            className="h-24 w-full rounded-lg border border-[var(--border)] bg-[var(--card)] px-3 py-2"
            value={purpose}
            onChange={(e) => setPurpose(e.target.value)}
            placeholder="이번 검토의 맥락을 설명하세요."
          />
        </label>
      </div>

      <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
        {methods.map(({ type, label, icon: Icon }) => (
          <button
            key={type}
            type="button"
            onClick={() => setInputType(type)}
            className={`rounded-xl border-2 p-4 text-center transition-colors ${
              inputType === type
                ? "border-[var(--primary)] bg-[var(--primary)]/10"
                : "border-[var(--border)] bg-[var(--card)] hover:border-[var(--primary)]/40"
            }`}
          >
            <Icon className="mx-auto mb-2 h-6 w-6" />
            <span className="text-sm font-semibold">{label}</span>
          </button>
        ))}
      </div>

      {inputType === "PASTE" && (
        <label className="block space-y-2">
          <span className="text-sm font-medium">코드 / 문서</span>
          <textarea
            required
            className="min-h-48 w-full rounded-lg border border-[var(--border)] bg-[var(--card)] p-3 font-mono text-sm"
            value={rawInput}
            onChange={(e) => setRawInput(e.target.value)}
            placeholder="검토할 내용을 붙여넣으세요."
          />
        </label>
      )}

      {inputType === "FILE" && (
        <label className="block space-y-2">
          <span className="text-sm font-medium">파일 업로드</span>
          <input
            required
            type="file"
            accept=".js,.ts,.tsx,.py,.java,.md,.txt,.json"
            className="w-full rounded-lg border border-[var(--border)] bg-[var(--card)] px-3 py-2"
            onChange={(e) => setFile(e.target.files?.[0] ?? null)}
          />
        </label>
      )}

      {inputType === "COMMIT" && (
        <div className="grid gap-4 sm:grid-cols-2">
          <label className="block space-y-2">
            <span className="text-sm font-medium">Repository URL</span>
            <input
              required
              className="w-full rounded-lg border border-[var(--border)] bg-[var(--card)] px-3 py-2"
              value={repoUrl}
              onChange={(e) => setRepoUrl(e.target.value)}
            />
          </label>
          <label className="block space-y-2">
            <span className="text-sm font-medium">Commit Hash</span>
            <input
              required
              className="w-full rounded-lg border border-[var(--border)] bg-[var(--card)] px-3 py-2 font-mono"
              value={commitHash}
              onChange={(e) => setCommitHash(e.target.value)}
            />
          </label>
        </div>
      )}

      {inputType === "PR" && (
        <div className="grid gap-4 sm:grid-cols-2">
          <label className="block space-y-2">
            <span className="text-sm font-medium">Repository URL</span>
            <input
              required
              className="w-full rounded-lg border border-[var(--border)] bg-[var(--card)] px-3 py-2"
              value={repoUrl}
              onChange={(e) => setRepoUrl(e.target.value)}
            />
          </label>
          <label className="block space-y-2">
            <span className="text-sm font-medium">PR Number</span>
            <input
              required
              type="number"
              min={1}
              className="w-full rounded-lg border border-[var(--border)] bg-[var(--card)] px-3 py-2"
              value={prNumber}
              onChange={(e) => setPrNumber(e.target.value)}
            />
          </label>
        </div>
      )}

      {error && (
        <p className="rounded-lg border border-red-300 bg-red-50 px-3 py-2 text-sm text-red-700 dark:bg-red-950/30 dark:text-red-300">
          {error}
        </p>
      )}

      <button
        type="submit"
        disabled={loading}
        className="rounded-lg bg-[var(--primary)] px-6 py-2.5 font-semibold text-[var(--primary-foreground)] disabled:opacity-50"
      >
        {loading ? "저장 중…" : "다음: 작업 맥락"}
      </button>
    </form>
  );
}
