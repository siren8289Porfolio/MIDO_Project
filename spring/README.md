# MIDO Backend (Spring Boot)

Verification API 백엔드. Manual Input / 파일 업로드 / Work Context 조회 API 제공.

## 구조

```
spring/
├── docs/
│   └── openapi.yaml    # API 스펙 (Swagger UI 등에서 사용)
├── src/main/
│   ├── java/com/mido/verification/
│   │   ├── VerificationApplication.java
│   │   ├── common/
│   │   │   ├── dto/         # ApiResponseVoid
│   │   │   ├── entity/      # VerificationData
│   │   │   └── repository/  # VerificationDataRepository
│   │   ├── manual/
│   │   │   ├── controller/
│   │   │   ├── service/
│   │   │   ├── repository/
│   │   │   ├── entity/
│   │   │   └── dto/
│   │   ├── upload/
│   │   │   ├── controller/
│   │   │   ├── service/
│   │   │   ├── repository/
│   │   │   └── entity/
│   │   └── context/
│   │       ├── controller/
│   │       ├── service/
│   │       ├── repository/
│   │       ├── entity/
│   │       └── dto/
│   └── resources/
│       └── application.yml
├── build.gradle.kts
├── settings.gradle.kts
├── gradlew
└── README.md
```

## 실행

```bash
# 프로젝트 루트(MIDO)에서
cd spring
./gradlew bootRun
```

- 서버: http://localhost:8080  
- API: `/api/verifications/*`  
- DB: PostgreSQL (로컬 `localhost:5432/mido`) — `application.yml`에서 변경 가능

## CI

백엔드 CI는 리포 루트의 `.github/workflows/backend-ci.yml`에서 `working-directory: spring`으로 실행됨.
