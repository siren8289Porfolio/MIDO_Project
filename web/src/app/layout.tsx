import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "MIDO",
  description: "AI Code Responsibility Layer — Verification Workflow",
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ko">
      <body>{children}</body>
    </html>
  );
}
