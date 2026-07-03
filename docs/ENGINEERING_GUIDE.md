# MIDO Engineering Guide

MIDO Spring Boot 백엔드 개발·운영에 필요한 핵심 개념 정리 문서.
SRS(`docs/SRS.md`) 구현과 운영 환경 구축 시 참고한다.

---

## 1. Java 코드 스타일 / Clean Code

### 1.1 이름 짓기

| 대상 | 규칙 | MIDO 예시 |
| --- | --- | --- |
| 클래스 | 명사, 역할이 드러나게 | `ManualInputService`, `WorkContextRepository` |
| 메서드 | 동사로 시작 | `create()`, `upload()`, `get()` |
| 변수 | 의미 있는 이름 | `verificationId`, `inputType` (❌ `data`, `temp`) |
| 상수 | `UPPER_SNAKE_CASE` | `MAX_FILE_SIZE_BYTES` |
| 불리언 | is/has/can 접두사 | `isBlank()`, `hasCode()` |

**원칙:** 이름만 봐도 역할을 알 수 있어야 한다. 주석으로 설명이 필요한 이름은 이름을 다시 짓는다.

### 1.2 클래스와 메서드 책임 분리

- **한 클래스 = 한 책임.** `ManualInputService`는 입력 생성만, `UploadService`는 업로드만 담당한다.
- **한 메서드 = 한 일.** `create()` 안에서 검증·저장·응답 조립을 하되, 검증 로직은 `validate()`로 분리한다.

```java
// ManualInputService.java — 검증과 생성 분리
public VerificationCreateResponse create(ManualInputRequest request) {
    validate(request);
    // ... 저장 로직
}

private void validate(ManualInputRequest request) { ... }
```

### 1.3 중복 제거

- inputType별 필수값 검증이 여러 곳에 흩어지면 `validate()` 한 곳으로 모은다.
- `requireNotBlank()` 같은 작은 헬퍼로 반복 메시지·조건을 줄인다.
- 응답 조립이 반복되면 `WorkContextResponse.from(ctx)` 같은 팩토리 메서드를 쓴다.

### 1.4 예외 처리

| 원칙 | 설명 |
| --- | --- |
| 빠르게 실패 | 잘못된 입력은 Service 초반에서 `IllegalArgumentException` |
| 의미 있는 메시지 | `"rawInput is required for PASTE"` — 필드와 조건 명시 |
| 계층별 책임 | Service는 비즈니스 예외 throw, Controller/Advice가 HTTP 변환 |
| 삼키지 않기 | `catch (Exception e) {}` 금지, 로그 + 재throw 또는 변환 |

**MIDO 현재 갭 (G-002):** `GlobalExceptionHandler` 미구현 → ERR-001~009 표준 응답 필요.

### 1.5 DTO, Entity, Service 역할 구분

| 계층 | 역할 | MIDO 예시 |
| --- | --- | --- |
| **Entity** | DB 테이블과 1:1 매핑, 영속성 | `VerificationData`, `ManualInput` |
| **DTO** | API 입출력, 화면용 데이터 | `ManualInputRequest`, `WorkContextResponse` |
| **Service** | 비즈니스 규칙, 트랜잭션, 조합 | `ManualInputService`, `UploadService` |

```
Client → DTO(Request) → Service → Entity → Repository → DB
Client ← DTO(Response) ← Service ← Entity
```

---

## 2. Spring DI / 계층 분리

### 2.1 Controller, Service, Repository 역할

```
HTTP 요청
  ↓
Controller   — URL 매핑, 요청/응답 변환, HTTP 상태 코드
  ↓
Service      — 비즈니스 로직, 트랜잭션, 여러 Repository 조합
  ↓
Repository   — DB CRUD, 쿼리
  ↓
Database
```

**MIDO 예시:**

```java
// Controller — HTTP만 담당
@PostMapping("/manual")
public ResponseEntity<VerificationCreateResponse> create(@RequestBody ManualInputRequest request) {
    return ResponseEntity.status(HttpStatus.CREATED).body(manualInputService.create(request));
}

// Service — BR-001 원자적 생성
@Transactional
public VerificationCreateResponse create(ManualInputRequest request) { ... }

// Repository — 데이터 접근
public interface WorkContextRepository extends JpaRepository<WorkContext, UUID> {
    Optional<WorkContext> findByVerificationData_Id(UUID verificationDataId);
}
```

### 2.2 의존성 주입 (DI)

Spring이 `@Service`, `@Repository`, `@RestController` 빈을 생성하고 생성자에 필요한 의존성을 넣어준다.

```java
public ManualInputController(ManualInputService manualInputService) {
    this.manualInputService = manualInputService;
}
```

### 2.3 객체를 직접 만들지 않고 주입받는 이유

| 직접 생성 (`new`) | DI (주입) |
| --- | --- |
| 구현체에 강하게 결합 | 인터페이스/추상에 의존 가능 |
| 테스트 시 Mock 교체 어려움 | `@MockBean`으로 단위 테스트 용이 |
| 설정 변경 시 코드 수정 필요 | `@Profile`, `@Qualifier`로 환경별 교체 |

```java
// ❌ Service 안에서 직접 생성
VerificationData data = new VerificationData();

// ✅ Spring이 관리하는 Repository 사용
verificationDataRepository.save(data);
```

> Entity는 **새로 저장할 때** `new`로 생성하는 것이 맞다. Repository·Service 같은 **인프라/협력 객체**는 주입받는다.

### 2.4 계층 분리가 유지보수에 좋은 이유

- Controller만 바꿔도 API 스펙 변경 가능 (Service 불변)
- DB 스키마 변경은 Entity/Repository에만 영향
- 비즈니스 규칙 변경은 Service만 수정
- 테스트를 계층별로 독립 실행 가능

---

## 3. Clean Architecture / Dependency Rule

### 3.1 의존성 방향

```
[외부] Controller, JPA, PostgreSQL, Git API, LLM API
         ↓ 의존
[애플리케이션] Service, Use Case
         ↓ 의존
[도메인] Entity, Business Rule (BR-001~012)
```

**규칙:** 안쪽(도메인)은 바깥(프레임워크, DB)을 모른다. 바깥이 안쪽을 의존한다.

### 3.2 비즈니스 로직과 외부 기술 분리

| 분리 대상 | MIDO 적용 |
| --- | --- |
| HTTP | Controller |
| DB | Repository + JPA Entity |
| 비즈니스 규칙 | Service (`validate`, `determineNextAction`) |
| 외부 Git/LLM | v1.0에서 `GitClient`, `AnalysisClient` 인터페이스로 분리 권장 |

### 3.3 테스트 가능한 구조

```java
// Service 단위 테스트 — Repository를 Mock으로 교체
@ExtendWith(MockitoExtension.class)
class ManualInputServiceTest {
    @Mock VerificationDataRepository verificationDataRepository;
    @InjectMocks ManualInputService manualInputService;

    @Test
    void paste_withoutRawInput_throws() {
        assertThrows(IllegalArgumentException.class,
            () -> manualInputService.create(pasteRequestWithoutRawInput()));
    }
}
```

### 3.4 변경 영향 범위 줄이기

- inputType 추가 → `validate()` switch + enum 상수만 수정
- 응답 필드 추가 → DTO만 수정, Entity는 필요 시만
- DB 변경 → Flyway migration + Entity (§14)

---

## 4. Entity / DTO / Value Object

### 4.1 Entity란

- **식별자(id)** 로 구분되는 영속 객체
- 생명주기 동안 **상태가 변할 수 있음** (`code`, `updatedAt` 갱신)
- JPA가 DB 테이블과 동기화

### 4.2 Entity와 Table의 관계

```java
@Entity
@Table(name = "verification_data")
public class VerificationData {
    @Id
    private UUID id;

    @Column(name = "input_type", nullable = false)
    private String inputType;
    // ...
}
```

| JPA | DB |
| --- | --- |
| `@Entity` 클래스 | 테이블 |
| `@Id` 필드 | PRIMARY KEY |
| `@Column` | 컬럼 정의 |
| `@OneToMany`, `@ManyToOne` | FK 관계 |

### 4.3 DTO와 Entity를 분리하는 이유

| 이유 | 설명 |
| --- | --- |
| API 계약 안정성 | DB 컬럼 변경이 API 응답에 직접 노출되지 않음 |
| 순환 참조 방지 | Entity 간 양방향 관계를 JSON으로내면 무한 루프 |
| 보안 | Entity의 내부 필드(`fileContent` 전체)를 그대로 노출하지 않음 |
| 검증 분리 | Request DTO에 `@NotBlank` 등 검증 어노테이션 적용 |

**MIDO:** `ManualInputRequest`(입력) → Service → `VerificationData`(저장) → `VerificationCreateResponse`(출력)

### 4.4 Value Object (VO)

- **식별자 없이 값 자체로 동등성**을 판단하는 불변 객체
- 예: `Money`, `Email`, `CommitHash`, `InputType` enum

```java
// enum으로 inputType을 VO화하면 switch 문자열 오타 방지
public enum InputType { PASTE, FILE, COMMIT, PR }
```

| Entity | Value Object |
| --- | --- |
| id로 구분 | 값으로 구분 |
| 가변 가능 | 불변 권장 |
| DB 테이블 | 보통 컬럼 또는 임베디드 |

---

## 5. Repository / JPA

### 5.1 Repository 역할

- Entity의 **영속화(저장·조회·삭제)** 추상화
- Service가 SQL을 직접 쓰지 않게 한다

### 5.2 CRUD

`JpaRepository<T, ID>`가 기본 제공:

| 메서드 | 역할 |
| --- | --- |
| `save(entity)` | INSERT 또는 UPDATE |
| `findById(id)` | PK 조회 |
| `findAll()` | 전체 조회 |
| `deleteById(id)` | 삭제 |

### 5.3 Query Method

메서드 이름으로 쿼리 자동 생성:

```java
// WorkContextRepository
Optional<WorkContext> findByVerificationData_Id(UUID verificationDataId);

// UploadedFileRepository
Optional<UploadedFile> findTopByVerificationDataOrderByUploadedAtDesc(VerificationData data);
```

**네이밍 패턴:** `findBy` + `필드명` + `조건(OrderBy, Top, First...)`

### 5.4 Custom Query

복잡한 쿼리는 `@Query` 사용:

```java
@Query("SELECT v FROM VerificationData v WHERE v.inputType = :type AND v.createdAt >= :since")
List<VerificationData> findRecentByType(@Param("type") String type, @Param("since") Instant since);
```

Native SQL:

```java
@Query(value = "SELECT * FROM verification_data WHERE status = ?1", nativeQuery = true)
List<VerificationData> findByStatusNative(String status);
```

### 5.5 Service → Repository 흐름

```
ManualInputService.create()
  → verificationDataRepository.save(data)
  → manualInputRepository.save(manualInput)
  → workContextRepository.save(context)
  → @Transactional — 하나라도 실패하면 전체 롤백 (BR-001)
```

---

## 6. Java Collections 자료구조

### 6.1 언제 무엇을 쓰는지

| 자료구조 | 특징 | 사용 시점 | 시간복잡도 (주요 연산) |
| --- | --- | --- | --- |
| **List** | 순서 O, 중복 O | 조회 결과 목록, 순서 보장 | get: O(1) ArrayList |
| **Set** | 순서 X, 중복 X | 중복 제거, 존재 여부 확인 | contains: O(1) HashSet |
| **Map** | key-value | ID로 조회, 그룹핑 | get/put: O(1) HashMap |
| **Queue** | FIFO | 대기열, BFS | offer/poll: O(1) |
| **PriorityQueue** | 우선순위 정렬 | severity 높은 리스크 먼저 처리 | offer/poll: O(log n) |
| **Deque** | 양방향 삽입/삭제 | 슬라이딩 윈도우, undo 스택 | addFirst/Last: O(1) |
| **TreeMap** | key 정렬 | 날짜순 이력, 범위 조회 | get: O(log n) |
| **TreeSet** | 정렬 + 중복 없음 | 정렬된 유니크 목록 | add: O(log n) |

### 6.2 MIDO 적용 예시

```java
// 리스크를 severity 순으로 정렬해 상위 5개만 반환
PriorityQueue<RiskItem> queue = new PriorityQueue<>(Comparator.comparing(RiskItem::getSeverity).reversed());

// inputType별 카운트 집계
Map<String, Long> countByType = verifications.stream()
    .collect(Collectors.groupingBy(VerificationData::getInputType, Collectors.counting()));

// 처리한 verification ID 중복 방지
Set<UUID> processed = new HashSet<>();
```

---

## 7. 알고리즘 / 시간복잡도

### 7.1 기본 개념

| 표기 | 의미 | 예시 |
| --- | --- | --- |
| O(1) | 상수 시간 | HashMap.get, ArrayList.get(index) |
| O(log n) | 로그 시간 | Binary Search, TreeMap.get |
| O(n) | 선형 | 리스트 전체 순회 |
| O(n log n) | 정렬 | Collections.sort, Stream.sorted |
| O(n²) | 이중 반복 | naive 중복 비교 |

**공간복잡도:** 추가 메모리 사용량. `Set`으로 중복 제거 시 O(n) 추가 공간.

### 7.2 정렬 / 탐색

| 알고리즘 | 조건 | 복잡도 |
| --- | --- | --- |
| Linear Search | 정렬 불필요 | O(n) |
| Binary Search | **정렬된** 배열/리스트 | O(log n) |
| Hash 조회 | hashCode 기반 Map/Set | O(1) 평균 |

```java
// ✅ ID 조회 — DB PK 인덱스 O(log n)
verificationDataRepository.findById(id);

// ❌ 전체 조회 후 필터 — O(n)
findAll().stream().filter(v -> v.getId().equals(id));
```

### 7.3 반복문 최적화

- 루프 안에서 DB 호출(N+1) 피하기 → §8 N+1 참고
- 불필요한 중첩 루프 제거
- Stream은 가독성용, hot path에서는 단순 for가 나을 수 있음

### 7.4 중복 제거

```java
// O(n) — HashSet
List<UUID> unique = new ArrayList<>(new LinkedHashSet<>(ids));

// Stream distinct
list.stream().distinct().toList();
```

---

## 8. DB 쿼리 / 인덱스 / 실행계획

### 8.1 기본 SQL

```sql
-- WHERE: 조건 필터
SELECT * FROM verification_data WHERE input_type = 'PASTE';

-- JOIN: 테이블 연결
SELECT v.id, w.display_repo_url
FROM verification_data v
JOIN work_context w ON w.verification_data_id = v.id;

-- ORDER BY + LIMIT/OFFSET: 페이징
SELECT * FROM verification_data
ORDER BY created_at DESC
LIMIT 20 OFFSET 40;
```

### 8.2 Index

| 개념 | 설명 |
| --- | --- |
| **Index** | 조회 속도 향상, 쓰기 비용·저장 공간 증가 |
| **B-tree Index** | PostgreSQL 기본. `=`, `<`, `>`, `BETWEEN`, `ORDER BY`에 유리 |
| **복합 인덱스** | `(input_type, created_at)` — 왼쪽 컬럼부터 사용 |

**MIDO 권장 인덱스 (SRS §7):**

```sql
CREATE INDEX idx_verification_input_created ON verification_data(input_type, created_at);
CREATE INDEX idx_decision_verification ON decision_log(verification_data_id);
```

### 8.3 EXPLAIN

```sql
EXPLAIN ANALYZE
SELECT * FROM verification_data WHERE input_type = 'PASTE';
```

| 실행 계획 | 의미 |
| --- | --- |
| **Seq Scan (Full Scan)** | 전체 테이블 스캔 — 데이터 많으면 느림 |
| **Index Scan** | 인덱스 사용 — WHERE/JOIN 컬럼에 인덱스 필요 |
| **Nested Loop** | JOIN 시 작은 쪽 반복 — N+1과 연관 |

### 8.4 N+1 문제

```java
// ❌ N+1 — Verification 100건이면 쿼리 101번
List<VerificationData> list = verificationDataRepository.findAll();
for (VerificationData v : list) {
    v.getManualInputs().size(); // lazy load마다 SELECT
}

// ✅ Fetch Join
@Query("SELECT v FROM VerificationData v JOIN FETCH v.manualInputs WHERE v.id = :id")
Optional<VerificationData> findWithInputs(@Param("id") UUID id);
```

### 8.5 페이징 쿼리

```java
// Spring Data
Page<VerificationData> page = repository.findAll(PageRequest.of(0, 20, Sort.by("createdAt").descending()));
```

- **OFFSET이 크면** 느려짐 → 커서 기반 페이징(`WHERE created_at < :cursor`) 검토

---

## 9. Spring Boot Test

### 9.1 테스트 종류

| 종류 | 범위 | 어노테이션 | 용도 |
| --- | --- | --- | --- |
| **Unit Test** | 클래스 단위, Mock | `@ExtendWith(MockitoExtension.class)` | Service 로직, validate |
| **Integration Test** | Spring Context + DB | `@SpringBootTest` | 전체 흐름 |
| **Controller Test** | HTTP 레이어 | `@WebMvcTest` | API 계약, 상태 코드 |
| **Repository Test** | DB 레이어 | `@DataJpaTest` | Query Method, 제약조건 |

### 9.2 MIDO 테스트 예시 (SRS TC 기준)

```java
// TC-001: PASTE 입력 시 Verification 생성
@SpringBootTest
@AutoConfigureMockMvc
class ManualInputControllerTest {
    @Autowired MockMvc mockMvc;

    @Test
    void createPaste_returns201() throws Exception {
        mockMvc.perform(post("/api/verifications/manual")
                .contentType(MediaType.APPLICATION_JSON)
                .content("""
                    {"inputType":"PASTE","inputMethod":"TEXTAREA","rawInput":"code"}
                    """))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.status").value("DRAFT"))
            .andExpect(jsonPath("$.nextAction").value("VIEW_CONTEXT"));
    }
}

// TC-002: inputType 누락 시 400
@Test
void missingInputType_returns400() { ... }

// TC-004: 파일 업로드 후 code 갱신 — @DataJpaTest + Service
```

### 9.3 예외 케이스 / 회귀 테스트

- **예외 케이스:** 경계값(prNumber=0), null, 빈 문자열, 존재하지 않는 ID
- **회귀 테스트:** 버그 수정 시 해당 TC 추가 → CI에서 매 PR마다 실행
- **현재 MIDO:** `VerificationApplicationTests.contextLoads()`만 존재 → TC-001~010 추가 필요

---

## 10. 유지보수성

| 원칙 | 설명 | MIDO 적용 |
| --- | --- | --- |
| **모듈성** | 기능별 패키지 분리 | `manual/`, `upload/`, `context/` |
| **재사용성** | 공통 로직 추출 | `requireNotBlank()`, `ApiResponseVoid` |
| **분석 용이성** | 일관된 구조·이름 | Controller-Service-Repository 패턴 통일 |
| **수정 용이성** | 작은 클래스·메서드 | validate 분리 |
| **테스트 용이성** | DI + 계층 분리 | Service Mock 테스트 |
| **변경 영향 최소화** | DTO/Entity 분리, 인터페이스 | GitClient 추상화 (v1.0) |

---

## 11. Spring Boot External Config

### 11.1 환경 분리

```
local       — 개발자 로컬 (localhost DB)
dev         — 공유 개발 서버
staging     — 운영과 동일 구성, 테스트 데이터
production  — 실제 서비스
```

### 11.2 application.yml + profile

```yaml
# application.yml — 공통
spring:
  application:
    name: mido-verification

---
# application-local.yml
spring:
  config:
    activate:
      on-profile: local
  datasource:
    url: jdbc:postgresql://localhost:5432/mido
    username: postgres
    password: postgres

---
# application-prod.yml
spring:
  config:
    activate:
      on-profile: prod
  datasource:
    url: ${DB_URL}
    username: ${DB_USERNAME}
    password: ${DB_PASSWORD}
```

**실행:**

```bash
./gradlew bootRun --args='--spring.profiles.active=local'
```

### 11.3 환경 변수

| 방식 | 용도 |
| --- | --- |
| `application.yml` | 기본값, 구조 |
| 환경 변수 `${DB_URL}` | 비밀번호, 환경별 URL |
| `.env` (로컬만) | 개발 편의, **Git에 커밋 금지** |

**원칙:** 비밀번호·API Key는 코드/YAML에 하드코딩하지 않는다.

---

## 12. Docker / 배포 기초

### 12.1 Dockerfile (MIDO 예시)

```dockerfile
# Build stage
FROM eclipse-temurin:21-jdk AS build
WORKDIR /app
COPY spring/gradlew spring/build.gradle.kts spring/settings.gradle.kts ./
COPY spring/gradle ./gradle
COPY spring/src ./src
RUN ./gradlew bootJar --no-daemon

# Run stage
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/build/libs/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

### 12.2 build → image → container

```bash
# 1. JAR 빌드
cd spring && ./gradlew bootJar

# 2. 이미지 빌드
docker build -t mido-verification:0.0.1 .

# 3. 컨테이너 실행 (환경 변수 주입)
docker run -p 8080:8080 \
  -e SPRING_PROFILES_ACTIVE=prod \
  -e DB_URL=jdbc:postgresql://host:5432/mido \
  -e DB_USERNAME=mido \
  -e DB_PASSWORD=secret \
  mido-verification:0.0.1
```

| 용어 | 설명 |
| --- | --- |
| **Dockerfile** | 이미지 빌드 레시피 |
| **Image** | 실행 가능한 앱 스냅샷 |
| **Container** | 이미지의 실행 인스턴스 |

---

## 13. GitHub Actions CI/CD

### 13.1 workflow 흐름

```
Push / PR
  ↓
Checkout
  ↓
Setup Java 21
  ↓
./gradlew test        ← 테스트 자동화
  ↓
./gradlew bootJar     ← 빌드 자동화
  ↓
docker build & push   ← image build (선택)
  ↓
deploy to staging/prod
```

### 13.2 MIDO backend-ci 예시

```yaml
# .github/workflows/backend-ci.yml
name: Backend CI

on:
  push:
    branches: [main]
    paths: ['spring/**']
  pull_request:
    paths: ['spring/**']

jobs:
  build:
    runs-on: ubuntu-latest
    defaults:
      run:
        working-directory: spring

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '21'

      - name: Test
        run: ./gradlew test

      - name: Build JAR
        run: ./gradlew bootJar
```

**원칙:** main 머지 전에 test 통과 필수. SRS TC-001~010을 CI에 포함.

---

## 14. Flyway DB Migration

### 14.1 왜 쓰는가

- `ddl-auto: update`는 **개발 초기**에만 적합
- 운영에서는 **버전 관리된 SQL**로 스키마 변경 이력을 남긴다
- local / dev / staging / prod에 **같은 순서**로 적용

### 14.2 migration 파일

```
spring/src/main/resources/db/migration/
  V1__create_verification_data.sql
  V2__create_manual_input.sql
  V3__add_status_column.sql
  V4__create_decision_log.sql
```

```sql
-- V3__add_status_column.sql
ALTER TABLE verification_data
  ADD COLUMN status VARCHAR(20) NOT NULL DEFAULT 'DRAFT';
```

### 14.3 seed data

```sql
-- V5__seed_team_guideline.sql (dev/staging only — prod는 별도 정책)
INSERT INTO team_guideline (id, team_id, pattern, recommendation)
VALUES ('...', 'team-1', 'naming-convention', 'Use camelCase for variables');
```

### 14.4 Gradle 의존성

```kotlin
implementation("org.flywaydb:flyway-core")
implementation("org.flywaydb:flyway-database-postgresql")
```

**MIDO 갭 (G-001):** `status` 컬럼을 Flyway V3 migration으로 추가 권장.

---

## 15. Spring Boot Actuator

### 15.1 Health Check

```kotlin
// build.gradle.kts
implementation("org.springframework.boot:spring-boot-starter-actuator")
```

```yaml
# application.yml
management:
  endpoints:
    web:
      exposure:
        include: health,info,metrics
  endpoint:
    health:
      show-details: when_authorized
```

| Endpoint | 용도 |
| --- | --- |
| `GET /actuator/health` | 앱·DB 연결 상태 |
| `GET /actuator/metrics` | JVM, HTTP 요청 수 |
| `GET /actuator/info` | 빌드 버전, Git 커밋 |

```json
// GET /actuator/health
{
  "status": "UP",
  "components": {
    "db": { "status": "UP" },
    "diskSpace": { "status": "UP" }
  }
}
```

**운영:** 로드밸런서·K8s가 이 엔드포인트로 살아있는지 확인한다.

---

## 16. Kubernetes Probe

### 16.1 Probe 종류

| Probe | 질문 | 실패 시 |
| --- | --- | --- |
| **Startup** | 앱이 시작됐는가? | 재시작 (느린 시작 앱용) |
| **Liveness** | 앱이 살아있는가? | 컨테이너 재시작 |
| **Readiness** | 트래픽 받을 준비됐는가? | Service에서 제외 |

### 16.2 MIDO deployment 예시

```yaml
livenessProbe:
  httpGet:
    path: /actuator/health/liveness
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /actuator/health/readiness
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5

startupProbe:
  httpGet:
    path: /actuator/health
    port: 8080
  failureThreshold: 30
  periodSeconds: 10
```

**흐름:** Startup 통과 → Readiness UP → 트래픽 유입 → Liveness로 장시간 hang 감지

---

## 17. Logging / Metrics / Tracing

### 17.1 세 가지 기둥

| 구분 | 답하는 질문 | 도구 예시 |
| --- | --- | --- |
| **Logging** | 무슨 일이 일어났는가? | SLF4J + Logback, JSON 로그 |
| **Metrics** | 얼마나 자주/느린가? | Micrometer, Prometheus, Grafana |
| **Tracing** | 요청이 어디서 느려졌는가? | OpenTelemetry, Jaeger, Zipkin |

### 17.2 MIDO 로깅 권장

```java
@Slf4j
@Service
public class ManualInputService {
    public VerificationCreateResponse create(ManualInputRequest request) {
        log.info("Creating verification inputType={}", request.getInputType());
        // ...
    }
}
```

**구조화 로그 (운영):**

```json
{
  "timestamp": "2026-07-03T12:00:00Z",
  "level": "ERROR",
  "service": "mido-verification",
  "traceId": "abc123",
  "verificationId": "550e8400-...",
  "message": "WorkContext not found"
}
```

### 17.3 알림 기준 예시

| 메트릭 | 알림 조건 |
| --- | --- |
| HTTP 5xx 비율 | > 1% (5분) |
| API p95 응답 시간 | > 1초 (NFR-001) |
| DB connection pool | 사용률 > 80% |
| `/actuator/health` | status != UP |

---

## 18. Rollback / Graceful Shutdown

### 18.1 Graceful Shutdown

```yaml
# application.yml
server:
  shutdown: graceful

spring:
  lifecycle:
    timeout-per-shutdown-phase: 30s
```

**동작:** SIGTERM 수신 → 새 요청 거부 → 진행 중 요청 완료 대기 → 종료

### 18.2 배포 실패 시 롤백

```
배포 (v2)
  ↓
Readiness Probe 실패 / 5xx 급증
  ↓
알림 발생
  ↓
이전 이미지 태그로 롤백 (v1)
  ↓
kubectl rollout undo / CI rollback job
```

### 18.3 운영 장애 대응 흐름

```
1. 알림 수신 (Health DOWN, 5xx, latency)
2. 로그·메트릭·트레이스로 원인 좁히기
3. 최근 배포/DB migration 있었는지 확인
4. 필요 시 롤백 또는 scale out
5. 원인 수정 → hotfix → CI 통과 후 재배포
6. 사후 회고 (postmortem)
```

---

## 부록: MIDO 적용 체크리스트

| 영역 | 현재 | 다음 단계 |
| --- | --- | --- |
| Clean Code / 계층 | ✅ 기본 구조 | GlobalExceptionHandler, InputType enum |
| Entity/DTO | ✅ 분리됨 | status Entity 반영 (G-001) |
| Repository | ✅ Query Method | DecisionLog Repository 추가 |
| Test | ❌ contextLoads만 | TC-001~010 구현 |
| Config | ⚠️ 단일 yml | profile 분리 (local/prod) |
| Docker | ❌ | Dockerfile 추가 |
| CI | ❌ workflow 없음 | backend-ci.yml 복원 |
| Flyway | ❌ ddl-auto: update | V1~ migration 전환 |
| Actuator | ❌ | health endpoint 추가 |
| K8s Probe | — | 배포 시 설정 |
| Observability | ⚠️ DEBUG 로그 | 구조화 로그 + metrics |

---

## 참고 문서

- [docs/PRD.md](./PRD.md) — 제품 요구사항
- [docs/SRS.md](./SRS.md) — 시스템 요구사항
- [spring/docs/openapi.yaml](../spring/docs/openapi.yaml) — API 명세
