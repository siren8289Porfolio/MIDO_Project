"use client";

import { Shield, FileText, Activity, CheckCircle, LucideIcon } from "lucide-react";

const steps: { id: string; label: string; icon: LucideIcon }[] = [
  { id: "input", label: "판단 대상 입력", icon: FileText },
  { id: "context", label: "작업 맥락", icon: Activity },
  { id: "judgment", label: "판단 수행", icon: Shield },
  { id: "log", label: "판단 기록", icon: CheckCircle },
];

interface StepperProps {
  current: number;
}

export function Stepper({ current }: StepperProps) {
  return (
    <ol className="flex flex-wrap gap-2 sm:gap-4">
      {steps.map((step, index) => {
        const Icon = step.icon;
        const active = index === current;
        const done = index < current;
        return (
          <li
            key={step.id}
            className={`flex items-center gap-2 rounded-full border px-3 py-1.5 text-sm font-medium transition-colors ${
              active
                ? "border-[var(--primary)] bg-[var(--primary)] text-[var(--primary-foreground)]"
                : done
                  ? "border-emerald-500/40 bg-emerald-500/10 text-emerald-700 dark:text-emerald-300"
                  : "border-[var(--border)] bg-[var(--card)] text-[var(--muted)]"
            }`}
          >
            <Icon className="h-4 w-4" />
            <span className="hidden sm:inline">{step.label}</span>
            <span className="sm:hidden">{index + 1}</span>
          </li>
        );
      })}
    </ol>
  );
}
