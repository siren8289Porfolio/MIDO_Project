# MIDO Web (Next.js)

4단계 Verification Workflow UI. Spring Boot API와 연동합니다.

## 실행

```bash
# 1. 백엔드 (다른 터미널)
cd spring && ./gradlew bootRun

# 2. 프론트
cd web
npm install
npm run dev
```

브라우저: http://localhost:3000

`/api/*` 요청은 Next.js가 `http://localhost:8080`으로 프록시합니다 (`next.config.ts`).

## 프로덕션 배포

CI(`main` push)에서 백엔드·프론트 이미지를 GHCR에 푸시합니다.

| 서비스 | 이미지 |
|--------|--------|
| API | `ghcr.io/siren8289porfolio/portfolio-mido:latest` |
| UI | `ghcr.io/siren8289porfolio/portfolio-mido-web:latest` |

EC2 `docker-compose`에 `mido-web` 서비스를 추가하고, nginx는 `/` → `mido-web:3000`, `/api/` → `mido-app:8080`으로 라우팅합니다. 예시: `nginx/mido.conf.example`, `docker-compose.prod.yml`.

## 단계

1. **판단 대상 입력** — `POST /api/verifications/manual`, FILE 시 upload
2. **작업 맥락** — `GET /api/verifications/{id}/context`
3. **판단 수행** — Use/Fix/Ignore (리스크는 MVP-2 전 목 데이터)
4. **판단 기록** — 로컬 상태 (DecisionLog API MVP-2 예정)
