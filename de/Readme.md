MIDO — LOB 조회 제거·복합/부분 인덱스·쿼리 회귀 테스트 기반 DB 최적화

목록 API에서 Entity 전체 조회와 대용량 code LOB 로딩을 제거하고, 실제 조회 패턴에 맞춘 PostgreSQL 복합/Partial/FK 인덱스와 Flyway Migration, Hibernate Statistics 기반 SQL 수 회귀 테스트를 적용한 DB 성능·운영 안정성 개선 프로젝트

프로젝트 구분: 개인 프로젝트
핵심 역할: Query Optimization, DB Index 설계, Transaction Boundary 설계, Flyway Migration 관리, Query Count Regression Test
기술 스택: PostgreSQL, Spring Boot, Spring Data JPA, Hibernate, Flyway, SQL, Docker
주요 영역: DBA / Database Performance Engineering / Data Access Optimization / DE 기초
1. 문제 상황 및 요구사항
1-1. 프로젝트 배경

MIDO는 코드 검증·수동 입력·파일 업로드·작업 맥락 관리를 다루는 Spring Boot 기반 프로젝트입니다.

핵심 데이터 흐름은 다음과 같습니다.

사용자 입력
→ verification 생성
→ manual_input / uploaded_file 생성
→ work_context 연결
→ 목록 조회
→ context 조회

초기 구조에서는 기능 자체는 동작했지만 DB 조회와 운영 스키마 관점에서 몇 가지 문제가 있었습니다.

1-2. 발생한 문제
문제 1. 목록 API에서 Entity 전체 조회

목록 화면에서는 제목, 상태, 입력 유형, 생성일 같은 요약 정보만 필요합니다.

하지만 Entity 전체 조회를 사용할 경우:

verification_data
→ 전체 Entity 조회
→ code LOB까지 포함될 가능성

이 생길 수 있었습니다.

code는 상세 코드 본문이기 때문에 목록 20건을 보여주기 위해 모두 읽어야 하는 데이터가 아닙니다.

문제 2. Context API에서 대용량 LOB Lazy Load 가능

Context 조회 과정에서 verification_data.code에 접근하면 대용량 LOB가 불필요하게 Lazy Load될 수 있었습니다.

Context 조회
→ work_context
→ verification_data
→ code LOB Lazy Load 가능




즉 사용자는 파일 유형이나 작업 맥락만 보려는데 DB에서는 긴 코드 본문까지 읽을 수 있는 구조였습니다.

문제 3. 데이터 건수 증가에 따른 N+1 회귀 위험

현재는 정상 조회되더라도 Entity 관계나 Lazy Loading 방식이 바뀌면 SQL 수가 다시 증가할 수 있습니다.

따라서 단순히 “현재 빠르다”가 아니라:

목록 데이터 증가
≠
SQL 개수 증가

가 유지되어야 했습니다.

문제 4. 운영 DB 인덱스 관리 방식이 명확하지 않음

Entity에 @Index를 선언하는 것만으로는 운영 DB의 실제 변경 이력을 충분히 관리하기 어렵습니다.

운영에서는:

누가
언제
어떤 인덱스를
어떤 순서로 적용했는가

를 재현할 수 있어야 했습니다.

그래서 스키마 변경을 Flyway Migration으로 관리할 필요가 있었습니다.

문제 5. 실제 조회 조건과 인덱스 구조 불일치 가능성

주요 API에서는 다음 조회 패턴을 사용합니다.

WHERE status = ?
ORDER BY created_at DESC

WHERE input_type = ?
ORDER BY created_at DESC

WHERE status = 'DRAFT'
ORDER BY created_at DESC

context / uploaded_file / manual_input FK 조회

단일 컬럼 인덱스만 두거나 모든 컬럼을 무작정 인덱싱하는 것보다, 필터와 정렬이 함께 사용되는 실제 조회 패턴 기준으로 인덱스를 설계해야 했습니다.

2. 해결 요구사항

DBA 관점에서는 다음 목표를 설정했습니다.

목록 조회에서 필요 없는 LOB를 읽지 않는다.
조회 조건과 정렬 패턴에 맞는 복합 인덱스를 사용한다.
특정 상태만 자주 조회하는 경우 Partial Index를 적용한다.
FK 기반 조회 경로를 인덱스로 보강한다.
운영 스키마 변경은 Flyway Migration으로 관리한다.
EXPLAIN ANALYZE로 실행계획을 검증할 수 있어야 한다.
조회 SQL 개수를 회귀 테스트로 고정한다.
요청 전체에 DB Session이 유지되는 구조를 피한다.
3개 테이블 INSERT는 하나의 Transaction으로 관리한다.

DE 관점에서는 다음 항목을 가져갈 수 있습니다.

API가 필요한 데이터만 Projection하여 읽는다.
대용량 LOB와 메타데이터 조회 경계를 분리한다.
데이터 상태를 DB 컬럼으로 영속화한다.
스키마 변경을 versioned migration으로 관리한다.
쿼리 수와 DB 접근량을 테스트 가능한 Evidence로 만든다.
3. 원인 분석
3-1. 문제는 Row 수뿐 아니라 Row Width

DB 성능은 단순히 몇 행을 조회했는지만 보는 것이 아닙니다.

예를 들어 목록 20건을 조회한다고 해도 각 Row에 큰 code LOB가 포함되면:

20 rows
×
대용량 code
=
불필요한 I/O 증가

가 됩니다.

따라서 MIDO에서는 Row Count와 함께 Row Width를 줄이는 것이 중요했습니다.

3-2. Entity 조회가 항상 최선은 아님

목록 화면에서 Entity 전체가 필요하지 않기 때문에:

Entity 조회
→ API Response 변환

보다:

필요 Column
→ DTO Projection

이 더 적합하다고 판단했습니다.

특히 대용량 code 컬럼이 존재하기 때문에 Projection의 효과가 더 명확했습니다.

3-3. Context와 Detail의 데이터 요구량이 다름

Context API가 필요한 정보는:

입력 유형
파일 Metadata
작업 맥락

입니다.

반면 상세 코드 본문은:

code

입니다.

따라서 두 조회를 같은 Data Access Path로 처리할 필요가 없습니다.

이를 분리하지 않으면 Context만 보더라도 LOB가 함께 로딩될 수 있습니다.

3-4. 목록 Query는 Filter + Sort 조합

다음 Query를 보면:

WHERE status = ?
ORDER BY created_at DESC

단순히 status만 보는 게 아니라 정렬까지 함께 사용합니다.

그래서 다음과 같은 복합 인덱스가 실제 조회 패턴과 더 잘 맞습니다.

(status, created_at)

동일하게:

(input_type, created_at)

도 필터 + 최신순 정렬 패턴을 반영한 구조입니다.

4. 문제 해결 및 적용 과정
Step 1. Entity 전체 조회를 DTO Projection으로 변경

목록 API를 VerificationSummaryResponse Projection 기반으로 변경했습니다.

Before
verification_data Entity 전체 조회
→ code LOB 포함 가능
→ 연관 Entity 접근
→ Lazy Query 가능
After
VerificationSummaryResponse
→ 필요한 Column만 조회
→ code LOB 제외
→ join 1 + count 1




이를 통해 목록 API에서 불필요한 대용량 데이터를 읽지 않도록 했습니다.

Step 2. Context API에서 LOB 로딩 제거

Context 조회에서는 verification_data.code를 직접 접근하지 않도록 변경했습니다.

Before
work_context
→ verification_data
→ code LOB
After
work_context
→ display_input_type snapshot
→ uploaded_file metadata
→ code LOB 0회




즉 상세 본문과 메타데이터 조회 경계를 분리했습니다.

Step 3. 조회 전용 Transaction 적용

조회 API에는:

@Transactional(readOnly = true)

를 적용했습니다.

이 설정을 단순히 “무조건 빨라지는 옵션”으로 설명하지 않고:

이 메서드는 읽기만 수행한다

라는 Transaction 의도를 코드에 명확히 표현하는 용도로 사용했습니다.

Step 4. Open Session in View 비활성화

다음 설정을 적용했습니다.

spring.jpa.open-in-view=false




Before
Controller / View 단계
→ Lazy Loading 가능
→ 숨은 Query 발생 가능
After
Service Transaction
→ 필요한 데이터 조회 완료
→ Controller에서는 DB 추가 조회 없음

이 구조는 N+1과 Lazy Loading 문제를 더 빠르게 드러내도록 합니다.

5. Transaction 안정성 개선
Step 5. 3개 테이블 INSERT를 하나의 Transaction으로 처리

수동 입력 생성 시 다음 데이터가 함께 생성됩니다.

verification
manual_input
work_context

이 세 데이터는 하나의 업무 단위이기 때문에:

verification 성공
manual_input 성공
work_context 실패

처럼 중간 데이터만 남으면 안 됩니다.

따라서 하나의 @Transactional로 묶었습니다.

BEGIN

verification INSERT
manual_input INSERT
work_context INSERT

성공
→ COMMIT

하나라도 실패
→ ROLLBACK
6. PostgreSQL 인덱스 설계
Step 6. 실제 조회 패턴 기준 복합 인덱스

MIDO의 주요 목록 조건은 다음과 같습니다.

status + created_at
input_type + created_at

따라서 복합 인덱스를 구성했습니다.

(status, created_at)

(input_type, created_at)

이 구조는:

WHERE status = ?
ORDER BY created_at DESC

처럼 필터와 정렬을 함께 사용하는 Query에 맞춰 설계한 것입니다.

Step 7. Partial Index 적용

전체 Verification 중 특정 상태인 DRAFT만 반복 조회하는 패턴에 Partial Index를 적용했습니다.

WHERE status = 'DRAFT'




일반 Index
DRAFT
READY
RUNNING
DONE
FAILED
→ 전부 Index
Partial Index
DRAFT
→ 필요한 Row만 Index

목적은 전체 Table이 아니라 자주 사용하는 subset만 별도 인덱싱하는 것입니다.

Step 8. FK 인덱스 보강

다음 관계의 FK 조회에도 인덱스를 추가했습니다.

work_context
uploaded_file
manual_input

README 기준 Flyway Migration에는 복합·Partial·FK Index를 포함해 총 6개의 인덱스가 반영되어 있습니다.

7. 운영 스키마 변경 관리
Step 9. JPA @Index와 운영 DDL 분리

Entity에는 개발자가 조회 구조를 이해할 수 있도록 @Index를 선언했습니다.

하지만 실제 운영 DB 변경은:

V1__efficiency_optimization.sql

Flyway Migration으로 관리했습니다.

Entity @Index
→ 코드 레벨 구조 표현

Flyway
→ 실제 운영 Schema 변경 이력

두 역할을 분리한 것입니다.

Step 10. ddl-auto: validate

운영 환경에서는 Hibernate가 자동으로 Schema를 수정하지 않도록:

ddl-auto: validate

를 사용하고 실제 변경은 Flyway를 통해 적용하도록 구성했습니다.

Before 위험
Application 실행
→ ORM이 Schema 변경 가능
After
Application
→ Schema 검증

Flyway
→ Versioned DDL 적용

이 방식으로 운영 DB 변경을 재현 가능한 SQL 이력으로 관리했습니다.

8. 실행계획 검증
Step 11. EXPLAIN ANALYZE 검증 스크립트 추가

다음 Query를 검증할 수 있도록:

verify-db-efficiency.sql

을 구성했습니다.

검증 대상:

최신 목록 조회
DRAFT 목록 조회
Context FK 조회

확인 항목:

Seq Scan
Index Scan
Actual Rows
Actual Time

즉:

Index 생성 완료

에서 끝나지 않고:

EXPLAIN ANALYZE
→ Planner가 실제 Index를 사용하는지 확인

할 수 있도록 했습니다.

9. Hibernate Statistics 기반 회귀 테스트
Step 12. SQL 수를 테스트 기준으로 고정

N+1 문제는 응답이 정상이어도 숨어 있을 수 있습니다.

그래서 Hibernate Statistics를 사용해 SQL 실행 횟수를 테스트했습니다.

검증 기준은:

목록 API 5건
→ SQL 2개 이하

Context API
→ SQL 2개 이하
→ LOB 로딩 없음

입니다.

이 테스트의 핵심은:

현재 고침
→ 끝

이 아니라:

향후 Entity 조회로 회귀
→ SQL 수 증가
→ Test Fail

하도록 만든 것입니다.

10. 해결 결과 및 성과

MIDO는 현재 Repository에서 실제 운영 DB latency 개선율을 측정한 수치는 제공하지 않습니다.

README에서도 IF/golmok의 2만 건 측정값은 MIDO의 실측값이 아니라 설계 참고치라고 명시하고 있습니다.

따라서 성과는 실제 검증 가능한 구조와 Query Count를 중심으로 작성하는 것이 맞습니다.

측정/검증 항목	개선 전	개선 후	효과
목록 데이터 조회	Entity 전체	DTO Projection	LOB 제외
목록 SQL	Lazy/N+1 가능	Join 1 + Count 1	SQL 수 고정 구조
목록 5건 Query Count	증가 가능	2개 이하 검증	N+1 회귀 방지
Context LOB	Lazy Load 가능	0회 목표/구조	불필요 LOB 제거
Context SQL	증가 가능	2개 이하 검증	Query Count 회귀 방지
최신순 목록	Full Scan + Sort 가능	복합 Index 활용 구조	검색 경로 개선
DRAFT 조회	전체 Index/Scan 가능	Partial Index	대상 범위 축소
Schema 변경	ORM 중심 가능	Flyway Versioned Migration	변경 이력 관리
다중 INSERT	Partial Write 위험	Transaction	원자성 확보




11. DBA 관점 핵심 성과
① Large Object I/O Optimization
Entity 전체 조회
→ DTO Projection

code LOB
→ 목록에서 제외
② Query Count Control
N+1 가능
→ Join 1 + Count 1
→ Hibernate Statistics 회귀 테스트
③ Index Design
status + created_at
input_type + created_at
→ Composite Index

DRAFT
→ Partial Index

Context 관계
→ FK Index
④ Migration Management
JPA Schema Auto Change
→ X

Flyway Versioned SQL
→ O
⑤ Transaction Integrity
3 Table INSERT
→ Single Transaction
→ Failure 시 Rollback
12. DE 관점에서 가져갈 수 있는 부분

MIDO는 pivotSeoul처럼 Airflow/Spark 중심의 전형적인 DE 프로젝트는 아닙니다.

DE 포트폴리오에서는 Data Access Efficiency와 Data Contract/Schema Management 관점으로 가져가는 것이 맞습니다.

핵심 흐름은:

Operational PostgreSQL
       ↓
Projection Query
       ↓
Minimal Dataset
       ↓
API

그리고 DB Schema 변경은:

Entity Change
      ↓
Migration SQL
      ↓
Flyway
      ↓
Production Schema Validation

으로 관리했습니다.

즉 MIDO의 DE 포인트는:

필요한 데이터만 읽기
LOB / Metadata 경계 분리
Schema Versioning
DB Migration
Query Regression Test

에 있습니다.

13. 문제 해결 흐름 요약
[Problem]

목록 Entity 전체 조회
+
대용량 code LOB
+
Lazy Loading / N+1 가능
+
운영 Schema 변경 관리 불명확

        ↓

[Root Cause]

API가 필요한 데이터보다
DB에서 더 많은 데이터를 읽음

조회 Pattern과 Index 불일치 가능

Entity 변경과 운영 DDL 경계 불명확

        ↓

[Action]

DTO Projection
→ LOB 제거
→ readOnly Transaction
→ open-in-view=false
→ Composite / Partial / FK Index
→ Flyway
→ EXPLAIN ANALYZE
→ Hibernate Statistics Test

        ↓

[Result]

목록 Query
→ Join 1 + Count 1

5건 목록
→ SQL 2개 이하 검증

Context
→ SQL 2개 이하
→ LOB 로딩 제거 구조

운영 Schema
→ Versioned Migration
14. 회고 및 배운 점

첫째, DB 성능은 Row 수만 볼 것이 아니라 한 Row에서 실제 얼마나 많은 데이터를 읽는지도 중요하다는 점을 배웠습니다. MIDO에서는 대용량 code LOB를 목록과 Context 조회에서 제거하면서 Query 수뿐 아니라 읽는 데이터의 크기까지 줄이는 방향으로 개선했습니다.

둘째, N+1 문제는 한 번 고치는 것보다 다시 생기지 않도록 Test로 고정하는 것이 중요했습니다. Hibernate Statistics로 SQL 수를 직접 측정하면서 성능을 기능 테스트처럼 회귀 관리할 수 있었습니다.

셋째, 인덱스는 컬럼 하나씩 추가하는 것이 아니라 실제 WHERE + ORDER BY 패턴을 보고 설계해야 한다는 점을 확인했습니다. status + created_at, input_type + created_at처럼 필터와 정렬을 함께 고려했습니다.

넷째, 운영 DB에서는 ORM 자동 DDL보다 Migration History가 중요하다는 점을 배웠습니다. Flyway와 ddl-auto: validate를 사용해 Schema 변경을 재현 가능한 SQL로 관리했습니다.

다섯째, @Transactional도 단순 Annotation이 아니라 여러 테이블에 걸친 하나의 업무 단위를 어디까지 원자적으로 처리할 것인가를 정의하는 도구라는 점을 확인했습니다.

15. 현재 프로젝트에서 주장하지 않는 것

현재 Repository에서 근거가 없는 아래 내용은 포트폴리오 성과로 적지 않습니다.

PostgreSQL 실제 P95/P99 Latency 개선율
실제 2만 건 기준 몇 ms → 몇 ms 개선
TPS 증가율
CPU 사용률 감소
Disk I/O 감소량
Buffer Hit Rate 개선
Lock / Deadlock 튜닝
Isolation Level 최적화
Partitioning
BRIN
Materialized View
Backup / Restore
HA / Failover
RTO / RPO
AWS RDS / Aurora
PgBouncer

특히 README의 2만 건 EXPLAIN 관련 수치는 IF/golmok의 동일 패턴 측정값을 참고한 MIDO 설계치이므로 MIDO 성과 수치로 사용하면 안 됩니다.

16. 포트폴리오용 최종 설명

MIDO에서 Spring Data JPA 기반 목록·Context 조회의 DB 접근 비용을 개선했습니다. 목록 API는 Entity 전체 조회 대신 VerificationSummaryResponse DTO Projection을 사용해 대용량 code LOB 컬럼을 제외하고 join 1 + count 1 구조로 변경했습니다. Context API에서는 code를 Lazy Load하지 않고 display_input_type Snapshot과 파일 Metadata만 조회하도록 분리했습니다. 또한 spring.jpa.open-in-view=false, 조회 API의 @Transactional(readOnly = true)를 적용해 Service Transaction 밖에서 숨은 Query가 발생하는 구조를 차단했습니다. PostgreSQL에서는 status + created_at, input_type + created_at 복합 인덱스와 status='DRAFT' Partial Index, FK 인덱스를 Flyway Migration으로 관리하고 ddl-auto: validate를 적용했습니다. 마지막으로 Hibernate Statistics 기반 회귀 테스트로 목록 5건과 Context 조회 시 SQL이 각각 2개 이하인지 검증해 향후 N+1이나 LOB Lazy Loading이 다시 발생하면 테스트 단계에서 감지하도록 구성했습니다.

한 줄 성과

대용량 code LOB를 목록·Context 조회에서 제거하고, DTO Projection·복합/Partial Index·Flyway·Hibernate Statistics를 적용해 DB 읽기량과 SQL 수를 통제 가능한 구조로 개선했습니다.
