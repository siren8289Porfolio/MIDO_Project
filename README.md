# Mido 

## 1. 핵심 한 줄

> **Mido는 목록 API를 DTO Projection으로 바꿔 필요한 컬럼만 조회하고, Context API에서 대용량 `code` LOB 로딩을 제거했으며, Flyway migration과 Hibernate Statistics 테스트로 DB 인덱스·쿼리 수를 검증 가능하게 만든 프로젝트입니다.**

---

## 2. 효율화 배경

Mido는 코드 검증·수동 입력·파일 업로드·작업 맥락 관리를 다루는 Spring Boot 기반 백엔드입니다.

초기 구조에서는 문서상 성능 개선 항목은 정리되어 있었지만, 실제 코드에서는 목록 조회, Context 조회, DB 인덱스, 회귀 테스트가 완전히 고정되어 있지 않았습니다.

이번 개선은 단순히 코드를 정리한 것이 아니라, 아래 항목을 실제 코드와 DB migration으로 반영한 작업입니다.

```text
1. 목록 API에서 Entity 전체 조회 제거
2. DTO Projection으로 필요한 컬럼만 조회
3. Context API에서 code LOB 로딩 제거
4. 조회 API에 readOnly 트랜잭션 적용
5. open-in-view 비활성화
6. Flyway migration으로 운영 DB 인덱스 관리
7. Hibernate Statistics로 쿼리 수 회귀 테스트 추가
```

비전공자식으로 말하면,
기존에는 목록을 볼 때 **서류 전체 묶음과 긴 본문까지 같이 들고 오는 구조**였다면, 개선 후에는 **목록 화면에 필요한 요약 정보만 가져오고, 긴 본문은 정말 필요할 때만 여는 구조**입니다.

---

## 3. 코드 효율화 요약

| 항목                      | 내용                                                | 주요 파일                                                                                 |
| ----------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------------- |
| 계층 분리 + 생성자 DI          | Controller → Service → Repository 구조, `new` 없이 주입 | `manual/`, `upload/`, `context/`, `common/`                                           |
| DTO / Entity 분리         | API 입출력 객체와 DB 엔티티 분리                             | `ManualInputRequest`, `WorkContextResponse`, `VerificationSummaryResponse`            |
| 단일 트랜잭션 원자성             | 3테이블 INSERT를 하나의 `@Transactional`로 처리             | `ManualInputService.java`                                                             |
| 부분 UPDATE               | upload 시 `code` + `updatedAt`만 갱신                 | `UploadService.java`                                                                  |
| 생성 후 list 재조회 없음        | 생성 응답은 `VerificationCreateResponse`만 반환           | `ManualInputService.java`                                                             |
| open-in-view 끔          | 요청 전체에 DB 세션을 붙잡지 않음                              | `application.yml`                                                                     |
| 읽기 전용 트랜잭션              | 조회 API에 `@Transactional(readOnly = true)` 적용      | `WorkContextService.java`, `VerificationListService.java`                             |
| status DB 영속화           | DTO에만 있던 status를 DB 컬럼으로 저장                       | `VerificationStatus.java`, `VerificationData.java`                                    |
| 목록 API + DTO Projection | `code` LOB 제외, join 1 + count 1 구조                | `VerificationDataRepository.java`, `VerificationListService.java`                     |
| Context API LOB 제거      | `display_input_type` 스냅샷 + 파일 메타 조회               | `WorkContext.java`, `WorkContextService.java`                                         |
| GlobalExceptionHandler  | 400/500 응답 정합 + 예외 로깅                             | `GlobalExceptionHandler.java`                                                         |
| N+1 회귀 테스트              | 목록·context 쿼리 수 2개 이하 검증                          | `VerificationListServiceQueryCountTest.java`, `WorkContextServiceQueryCountTest.java` |

---

## 4. 목록 API: DTO Projection으로 경량화

### 기존 문제

기존 목록 조회가 Entity 전체를 가져오는 방식이면, 목록 화면에서 필요하지 않은 `code` 같은 대용량 컬럼까지 함께 조회될 수 있습니다.

```text
Before

verification_data Entity 전체 조회
→ code LOB 포함 가능
→ 연관 데이터 접근 시 lazy query 가능
→ 목록 20건이면 불필요한 데이터 읽기 증가
```

비전공자식으로 말하면,
목록에는 제목, 상태, 날짜 정도만 필요한데 **상세 본문 전체까지 같이 복사해 오는 것**입니다.

---

### 개선 후

목록 API는 `VerificationSummaryResponse` DTO Projection으로 필요한 값만 조회하도록 변경했습니다.

Spring Data JPA 공식문서는 DTO Projection을 “조회해야 할 필드 값을 담는 DTO 타입을 사용하는 방식”으로 설명합니다. 즉, Entity 전체가 아니라 화면에 필요한 값만 담는 응답 객체를 만들 수 있습니다.

```text
After

VerificationSummaryResponse DTO로 필요한 컬럼만 조회
→ code LOB 제외
→ join 1 + count 1
→ 목록 조회 SQL 수와 데이터 크기 감소
```

### 효과

```text
1. 목록 화면에 필요 없는 대용량 code 컬럼 제외
2. Entity 전체 로딩으로 인한 불필요한 데이터 읽기 감소
3. 목록 API 응답 구조 명확화
4. N+1 또는 lazy loading 회귀를 테스트로 감지 가능
```

---

## 5. 단일 트랜잭션으로 3테이블 INSERT 원자성 확보

`ManualInputService`에서는 verification, manual_input, work_context처럼 함께 생성되어야 하는 데이터를 하나의 `@Transactional` 안에서 처리했습니다.

Spring 공식문서에서 `@Transactional`은 클래스나 메서드에 트랜잭션 의미를 부여하는 메타데이터라고 설명합니다. 또한 `readOnly`는 읽기 전용 트랜잭션임을 나타내며 런타임 최적화에 활용될 수 있는 flag입니다.

```text
3테이블 INSERT 중 하나라도 실패
→ 전체 rollback
→ 중간 데이터만 남는 상태 방지
```

비전공자식으로 말하면,
한 세트로 저장되어야 하는 서류를 한 번에 접수하고, **중간에 하나라도 실패하면 전부 취소하는 구조**입니다.

---

## 6. 읽기 전용 트랜잭션 적용

조회 API에는 `@Transactional(readOnly = true)`를 적용했습니다.

```text
쓰기 API:
데이터 생성/수정 가능

조회 API:
데이터 변경 없음
→ readOnly 트랜잭션으로 의도 명확화
```

이건 “무조건 빨라진다”라기보다, **이 서비스는 데이터를 바꾸지 않는 조회용 로직이라는 의도를 코드와 트랜잭션 설정에 명확히 남긴 것**에 가깝습니다.

---

## 7. open-in-view 비활성화

Mido는 `spring.jpa.open-in-view=false`로 설정했습니다.

Spring Boot 공식문서는 웹 애플리케이션에서 기본적으로 Open EntityManager in View 패턴을 적용해 view 단계의 lazy loading을 허용하며, 원하지 않으면 `spring.jpa.open-in-view=false`로 설정하라고 안내합니다.

```text
open-in-view=true:
요청이 끝날 때까지 DB 세션 유지
→ Controller/View 단계에서도 lazy loading 가능
→ 숨은 쿼리 발생 가능

open-in-view=false:
Service 트랜잭션 안에서 필요한 데이터 조회 완료
→ 조회 책임이 Service 계층으로 모임
→ N+1을 더 빨리 발견 가능
```

비전공자식으로 말하면,
화면을 그리는 중간에 몰래 창고를 다시 다녀오지 못하게 하고, **서비스 단계에서 필요한 물건을 미리 챙겨오게 만든 구조**입니다.

---

## 8. Context API: LOB 컬럼 로딩 제거

### 기존 문제

Context API에서 `verification_data.code`를 직접 접근하면, 대용량 코드 본문이 불필요하게 lazy load될 수 있습니다.

```text
Before

Context 조회
→ work_context 조회
→ verification_data 접근
→ code LOB lazy load 가능
```

`code`는 목록·맥락 화면마다 항상 필요한 값이 아니라, 상세 코드가 필요한 순간에만 읽는 것이 맞습니다.

---

### 개선 후

Context API에서는 `verification_data.code`를 직접 lazy load하지 않도록 바꾸고, `display_input_type` 스냅샷과 파일 메타 조회로 응답을 구성했습니다.

```text
After

Context 조회
→ work_context 조회
→ uploaded_file 메타 조회
→ code LOB 로딩 없음
```

비전공자식으로 말하면,
목록이나 맥락 화면에서는 **긴 본문 파일을 열지 않고, 제목·종류·파일 정보만 보는 구조**입니다.

---

## 9. Hibernate Statistics 기반 회귀 테스트

N+1 문제는 화면이 정상 출력되어도 숨어 있을 수 있습니다.
그래서 Mido는 Hibernate Statistics로 실제 SQL 실행 횟수를 측정하는 회귀 테스트를 추가했습니다.

Hibernate `Statistics` 공식 Javadoc은 `hibernate.generate_statistics=true`로 통계 수집을 켤 수 있고, SessionFactory에 속한 세션들의 통계를 노출한다고 설명합니다.

```text
검증 기준

목록 API 5건
→ SQL 2개 이하

Context API
→ SQL 2개 이하
→ LOB 로딩 없음
```

이 테스트 덕분에 나중에 누군가 다시 Entity 전체 조회나 lazy loading 구조로 되돌려도, SQL 수가 증가하면서 테스트가 실패합니다.

비전공자식으로 말하면,
“고쳤다”에서 끝나는 게 아니라 **다시 느려지는 코드가 들어오면 자동으로 잡아내는 검사 장치**를 만든 것입니다.

---

## 10. 전역 예외 처리와 로깅

`GlobalExceptionHandler`를 추가해 400/500 응답을 정리하고, 처리되지 않은 예외는 로그로 남기도록 했습니다.

```text
Before

예외 발생
→ 응답 형식 불안정
→ 서버 로그에 원인 부족 가능

After

예외 발생
→ 400/500 응답 정리
→ 스택트레이스 로그 기록
→ 장애 원인 추적 가능
```

비전공자식으로 말하면,
오류가 났을 때 사용자에게는 정리된 안내를 보여주고, 개발자에게는 **어디서 왜 터졌는지 기록을 남기는 구조**입니다.

---

## 11. DB 효율화 요약

| 항목               | 내용                                                         | 주요 파일                                               |
| ---------------- | ---------------------------------------------------------- | --------------------------------------------------- |
| 테이블 책임 분리        | verification / manual_input / uploaded_file / work_context | 엔티티 4개                                              |
| JPA `@Index`     | `(status, created_at)`, `(input_type, created_at)`         | `VerificationData.java`                             |
| Flyway + 인덱스 DDL | status 컬럼, 복합/부분/FK 인덱스 6개                                 | `V1__efficiency_optimization.sql`                   |
| Partial Index    | `WHERE status = 'DRAFT'`                                   | `V1__efficiency_optimization.sql`                   |
| FK 인덱스           | work_context UNIQUE, uploaded_file, manual_input           | `V1__efficiency_optimization.sql`                   |
| EXPLAIN 검증 스크립트  | 목록·DRAFT·context FK 조회                                     | `verify-db-efficiency.sql`                          |
| prod Flyway 활성화  | `ddl-auto: validate` + migration                           | `application-prod.yml`                              |
| 설계 문서            | DB/코드 효율화 로드맵                                              | `DB_EFFICIENCY_SUMMARY.md`, `EFFICIENCY_SUMMARY.md` |

---

## 12. JPA `@Index`와 운영 DDL 분리

Mido는 Entity에 JPA `@Index`를 선언하고, 실제 운영 반영은 Flyway migration SQL로 분리했습니다.

운영 환경에서는 Entity annotation만 믿기보다, migration SQL로 명시하는 편이 안전합니다. 그래서 Mido는 `V1__efficiency_optimization.sql`에 status 컬럼과 인덱스를 함께 반영했습니다.

```text
Entity:
개발자가 구조를 이해하기 쉬운 선언

Flyway migration:
운영 DB에 실제 반영되는 SQL 이력
```

---

## 13. Flyway migration으로 운영 스키마 변경 관리

Mido는 `application-prod.yml`에서 `ddl-auto: validate`를 사용하고, 실제 스키마 변경은 Flyway migration으로 반영하도록 구성했습니다.

Flyway 공식문서는 migration이 개발 DB의 점진적 변경을 포착하는 SQL script이며, version control에 보관하고 여러 환경에 같은 순서로 적용해 반복 가능한 배포 프로세스를 만든다고 설명합니다.

```text
개발:
Entity 변경 확인

운영:
ddl-auto로 자동 변경하지 않음
Flyway migration으로 명시적 반영
```

즉, 운영 DB를 애플리케이션이 임의로 바꾸는 구조가 아니라, **버전이 있는 SQL로 스키마 변경 이력을 남기는 구조**입니다.

---

## 14. PostgreSQL 인덱스와 최신순 목록 조회

Mido 목록 API는 `created_at DESC LIMIT 20`처럼 최신순 목록을 자주 조회합니다.

PostgreSQL 공식문서는 인덱스가 특정 row를 더 빠르게 찾고 가져올 수 있게 하지만, DB 전체에는 overhead도 생기므로 신중하게 사용해야 한다고 설명합니다. 또한 인덱스는 특정 정렬 순서로 결과를 제공할 수 있어 `ORDER BY`를 별도 정렬 없이 처리하는 데 활용될 수 있습니다.

```text
Before

verification_data 전체 스캔
→ created_at 기준 정렬
→ 최신 20개 선택

After

(status, created_at) / (input_type, created_at) 인덱스 활용
→ 조회 조건과 정렬 순서에 맞춰 접근
→ 목록 조회 부담 감소
```

비전공자식으로 말하면,
전체 서류를 다 뒤져서 날짜순으로 다시 정렬하는 것이 아니라, **이미 최신순으로 정리된 색인표에서 필요한 만큼 가져오는 방식**입니다.

---

## 15. 복합 인덱스

Mido는 `status + created_at`, `input_type + created_at`처럼 조건과 정렬이 함께 쓰이는 조회에 복합 인덱스를 사용했습니다.

PostgreSQL 공식문서는 B-tree, GiST, GIN, BRIN 인덱스가 여러 key column을 가진 multicolumn index를 지원한다고 설명합니다.

```text
자주 쓰는 조회 패턴

WHERE status = ?
ORDER BY created_at DESC

WHERE input_type = ?
ORDER BY created_at DESC
```

즉, 단순히 컬럼마다 인덱스를 따로 만든 것이 아니라, **목록 API의 실제 필터 + 정렬 패턴에 맞춰 묶은 인덱스**입니다.

---

## 16. Partial Index

Mido는 `status = 'DRAFT'` 조건에 Partial Index를 추가했습니다.

PostgreSQL 공식문서는 Partial Index를 테이블 전체가 아니라 조건식을 만족하는 일부 행에 대해서만 만들어지는 인덱스라고 설명합니다.

```text
전체 verification_data:
DRAFT / READY / RUNNING / DONE / FAILED 등 여러 상태

DRAFT 목록:
DRAFT만 자주 조회

개선:
DRAFT인 row만 인덱싱
→ 인덱스 크기 감소
→ DRAFT 조회 시 스캔 범위 감소
```

비전공자식으로 말하면,
전체 서류철에 책갈피를 붙이는 게 아니라, **임시저장 서류철에만 따로 책갈피를 붙인 것**입니다.

---

## 17. EXPLAIN ANALYZE 검증

Mido는 `verify-db-efficiency.sql`로 목록, DRAFT, context FK 조회의 실행계획을 확인할 수 있게 했습니다.

PostgreSQL 공식문서는 `EXPLAIN`으로 planner가 어떤 query plan을 만드는지 볼 수 있고, `ANALYZE` 옵션을 붙이면 실제 실행 시간과 실제 반환 row 수가 표시된다고 설명합니다.

```text
느낌상 빠름
→ X

EXPLAIN ANALYZE로 확인
→ Seq Scan인지 Index Scan인지 확인
→ 실제 실행 시간 확인
```

비전공자식으로 말하면,
“빨라졌을 것 같다”가 아니라 **DB가 실제로 어떤 길로 데이터를 찾는지 지도처럼 확인하는 구조**입니다.

---

## 18. 측정/설계치 정리

아래 수치는 동일 패턴의 IF/golmok 2만 건 EXPLAIN 측정값을 참고한 Mido 설계치입니다. 실제 Mido 운영 DB의 정확한 수치는 데이터 분포와 row 크기에 따라 달라질 수 있으므로, `verify-db-efficiency.sql`로 재측정하는 것이 맞습니다.

| 쿼리                                              | 인덱스 없음                  | 인덱스 있음                                  | 설명            |
| ----------------------------------------------- | ----------------------- | --------------------------------------- | ------------- |
| `ORDER BY created_at DESC LIMIT 20`             | Seq Scan + Sort 가능      | `idx_verification_status_created` 활용 목표 | 최신순 목록 조회 최적화 |
| `WHERE status='DRAFT' ORDER BY created_at DESC` | Full Scan 가능            | `idx_verification_draft_created` 활용 목표  | DRAFT 행만 인덱싱  |
| 목록 LOB                                          | `SELECT *` 시 LOB 포함 가능  | Projection으로 LOB 제외                     | 목록 페이지 I/O 축소 |
| Context API                                     | `code` LOB lazy load 가능 | LOB 0회 로딩 목표                            | 메타데이터 중심 응답   |

문서에는 이렇게 쓰면 됩니다.

> Mido는 실제 운영 조회 패턴인 최신순 목록, status 필터, input_type 필터, context FK 조회에 맞춰 복합 인덱스와 Partial Index를 추가했습니다. 특히 목록 API는 DTO Projection으로 `code` LOB 컬럼을 제외해 `SELECT *` 대비 페이지당 읽기량을 줄이는 구조를 적용했습니다. 단, DB 실행시간 개선율은 데이터 분포에 따라 달라질 수 있으므로 `verify-db-efficiency.sql`의 `EXPLAIN ANALYZE`로 재측정하도록 구성했습니다.

---

## 19. 기존에 잘 되어 있던 부분

| 항목                            | 파일                                                |
| ----------------------------- | ------------------------------------------------- |
| Query Method 기반 FK 조회         | `WorkContextRepository`, `UploadedFileRepository` |
| FILE 2단계 API, create → upload | `ManualInputController`, `UploadController`       |
| Context API LOB 미포함 응답 설계     | `WorkContextResponse`                             |

이 부분은 구조 자체가 이미 괜찮아서, 이번 작업에서는 성능 회귀 테스트와 LOB lazy load 제거 쪽을 보강했습니다.

---

## 20. 커밋·푸시

| 커밋        | 내용                                                                                            |
| --------- | --------------------------------------------------------------------------------------------- |
| `9c05f37` | status 영속화, Flyway 인덱스, 목록 projection API, LOB-free context, GlobalExceptionHandler, 쿼리 수 테스트 |
| `f057b28` | IF 효율화                                                                                        |
| `086b1fd` | golmok MV 비동기 리프레시                                                                            |

원격 `main`에 푸시 완료.

---

## 21. 공식문서 근거 요약

| 적용 내용                    | 공식문서                                     |
| ------------------------ | ---------------------------------------- |
| DTO Projection           | Spring Data JPA Projections              |
| 트랜잭션 처리                  | Spring `@Transactional`                  |
| 읽기 전용 트랜잭션               | Spring `@Transactional(readOnly = true)` |
| open-in-view 비활성화        | Spring Boot Open EntityManager in View   |
| Hibernate Statistics 테스트 | Hibernate `Statistics`                   |
| Flyway migration         | Flyway Migrations                        |
| PostgreSQL ORDER BY 인덱스  | PostgreSQL Indexes and ORDER BY          |
| PostgreSQL 복합 인덱스        | PostgreSQL Multicolumn Indexes           |
| PostgreSQL Partial Index | PostgreSQL Partial Indexes               |
| 실행계획 검증                  | PostgreSQL EXPLAIN / EXPLAIN ANALYZE     |

---

## 22. 최종 요약 문장

Mido의 코드 효율화는 문서에만 있던 성능 개선 항목을 실제 목록 API, Context API, DB migration, 회귀 테스트로 고정한 작업입니다.

목록 API는 Entity 전체 조회 대신 DTO Projection을 사용하도록 변경해 `code` LOB 컬럼을 제외하고, join 1회 + count 1회로 SQL 수를 고정했습니다. Spring Data JPA는 DTO Projection을 공식 지원하며, 화면에 필요한 필드만 담는 조회 구조를 만들 수 있습니다.

Context API는 `verification_data.code` LOB lazy load를 제거하고, `display_input_type` 스냅샷과 file 메타 조회로 응답을 구성하도록 변경했습니다. 대용량 데이터는 목록·맥락 조회에서 불필요하게 읽지 않도록 분리하는 것이 중요합니다.

DB 효율화는 `V1__efficiency_optimization.sql` Flyway migration으로 status 컬럼, 복합 인덱스, Partial Index, FK 인덱스를 반영했습니다. Flyway migration은 DB 변경을 버전이 있는 SQL로 관리하고 여러 환경에 같은 순서로 적용하는 방식이므로, 운영 `ddl-auto: validate` 구조와 함께 사용하기 적합합니다.

또한 Hibernate Statistics 기반 테스트를 추가해 목록 API와 Context API의 SQL 수가 2개 이하로 유지되는지 검증했습니다. 이로써 향후 Entity 전체 조회나 lazy loading이 다시 들어와도 테스트 단계에서 성능 회귀를 잡을 수 있게 되었습니다. 이번 변경은 `9c05f37` 커밋으로 원격 `main`에 푸시 완료했습니다.

---

## 23. 한 줄 설명

> **Mido는 목록 API를 DTO Projection으로 바꿔 SQL 수를 2개로 고정하고, Context API에서 `code` LOB 로딩을 제거했으며, Flyway 인덱스와 Hibernate Statistics 테스트로 조회 성능 회귀를 방지한 코드·DB 효율화 프로젝트입니다.**

---

## 24. 포트폴리오 카드용 문장

> **목록 API를 DTO Projection으로 전환해 대용량 `code` LOB 컬럼을 제외하고, Context API에서도 LOB 로딩을 제거했습니다. Flyway 인덱스와 Hibernate Statistics 기반 쿼리 수 테스트를 추가해 운영 DB 반영과 성능 회귀 방지를 함께 구성했습니다.**
