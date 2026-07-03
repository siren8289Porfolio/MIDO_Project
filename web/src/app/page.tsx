"use client";

import { useState } from "react";
import { Moon, Shield, Sun } from "lucide-react";
import { Stepper } from "@/components/Stepper";
import { ManualInputStep } from "@/components/ManualInputStep";
import { WorkContextStep } from "@/components/WorkContextStep";
import { JudgmentStep } from "@/components/JudgmentStep";
import { DecisionLogStep } from "@/components/DecisionLogStep";
import type { DecisionRecord, VerificationSession } from "@/types";

export default function HomePage() {
  const [step, setStep] = useState(0);
  const [dark, setDark] = useState(false);
  const [session, setSession] = useState<VerificationSession | null>(null);
  const [record, setRecord] = useState<DecisionRecord | null>(null);

  function restart() {
    setStep(0);
    setSession(null);
    setRecord(null);
  }

  return (
    <div className={dark ? "dark" : ""}>
      <div className="min-h-screen bg-[var(--background)] text-[var(--foreground)]">
        <header className="sticky top-0 z-10 border-b border-[var(--border)] bg-[var(--background)]/90 backdrop-blur">
          <div className="mx-auto flex max-w-4xl items-center justify-between gap-4 px-4 py-4 sm:px-6">
            <div className="flex items-center gap-3">
              <div className="rounded-xl bg-[var(--primary)] p-2 text-[var(--primary-foreground)]">
                <Shield className="h-6 w-6" />
              </div>
              <div>
                <h1 className="text-xl font-bold">MIDO</h1>
                <p className="text-xs text-[var(--muted)]">AI Code Responsibility Layer</p>
              </div>
            </div>
            <button
              type="button"
              aria-label="Toggle theme"
              onClick={() => setDark((d) => !d)}
              className="rounded-full border border-[var(--border)] p-2"
            >
              {dark ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
            </button>
          </div>
          <div className="mx-auto max-w-4xl px-4 pb-4 sm:px-6">
            <Stepper current={step} />
          </div>
        </header>

        <main className="mx-auto max-w-4xl px-4 py-8 sm:px-6">
          {step === 0 && (
            <ManualInputStep
              session={session}
              onComplete={(s) => {
                setSession(s);
                setStep(1);
              }}
            />
          )}
          {step === 1 && session && (
            <WorkContextStep
              session={session}
              onBack={() => setStep(0)}
              onNext={() => setStep(2)}
            />
          )}
          {step === 2 && session && (
            <JudgmentStep
              session={session}
              onBack={() => setStep(1)}
              onComplete={(decision, rationale) => {
                setRecord({
                  decision,
                  rationale,
                  decidedAt: new Date().toISOString(),
                });
                setStep(3);
              }}
            />
          )}
          {step === 3 && session && record && (
            <DecisionLogStep session={session} record={record} onRestart={restart} />
          )}
        </main>
      </div>
    </div>
  );
}
