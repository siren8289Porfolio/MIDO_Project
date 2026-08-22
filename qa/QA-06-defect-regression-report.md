# QA-06 Defect & Regression Report

> **정합성 기준:** PRD_v0 · SRS_v0 · SDD_v0

> **판정 원칙:** 실행 증거 없는 기능·테스트는 PASS가 아니라 PLANNED 또는 NOT RUN이다. AI는 승인자가 아니며 사람의 Use/Fix/Ignore 및 리뷰 승인을 우회할 수 없다.

---

## 1. 목적

결함과 회귀 위험을 요구사항·컴포넌트·테스트·릴리스에 연결한다. 실제 실행 실패가 없으므로 가상의 product defect를 만들지 않는다.

---

## 2. 결함 분류

- Functional: 요구 결과·상태·API
- Data: transaction / FK / duplicate / migration
- Security / Privacy: auth, ACL, secret / PII, upload
- AI Safety: unsupported claim, evidence, injection, auto-approval
- Performance: query / latency / lock / LOB
- Reliability: timeout / retry / idempotency / recovery
- Documentation / Contract: PRD / SRS / SDD / code 불일치
- Analytics: event / metric / grain 오류

---

## 3. 심각도

- S1 / P0: 데이터 손상·권한 / secret 누출·자동 승인·서비스 중단.
- S2 / P1: 핵심 기능 실패·부분 저장·치명 위험 누락·계약 파손.
- S3 / P2: 우회 가능한 기능 / 성능 / 분석 오류.
- S4 / P3: 경미한 UI / 문서 문제.

---

## 4. 문서 검토에서 발견·교정한 항목

- DOC-001 상태명이 PROCESSING과 RUNNING으로 혼재 → 직군 문서 RUNNING 통일, baseline patch 필요
- DOC-002 status / GlobalExceptionHandler 구현 상태가 과거 기준 → 현재 근거로 교정
- DOC-003 Context에서 LOB 노출 경계 불명확 → 일반 응답 제외 명시
- DOC-004 AI / Decision / Approval을 구현된 것처럼 읽힐 위험 → PLANNED / NOT TESTED 표기

이 항목은 정적 문서 결함이며 실제 코드 defect로 판정하지 않는다.

---

## 5. 결함 레코드

defect_id, summary, detected_run / case, severity / priority, affected requirement / component / version, steps, expected / actual, evidence, root cause, fix commit, regression cases, owner, status, verification result를 기록한다.

---

## 6. 회귀 세트

- manual 3-table atomic creation
- upload partial update와 validation
- context / list projection과 LOB exclusion
- persisted status transition
- common exception response
- migration / constraints / index
- query count ≤2
- AI contract / safety / human control
- DecisionLog immutability / RBAC
- metric / event contract

---

## 7. Root Cause

requirements gap, design gap, code defect, data / schema, configuration, dependency / provider, test gap, operational process로 분류하고 예방 조치를 기록한다.

동일 원인이 2회 이상 반복되면 systemic action을 만든다.

---

## 8. 현재 판정

실제 test run이 없으므로 product defect open / closed 통계를 산출하지 않는다.

QA-05 실행 후 본 문서를 갱신하고, S1 / S2 미해결이면 QA-07은 NO-GO다.

