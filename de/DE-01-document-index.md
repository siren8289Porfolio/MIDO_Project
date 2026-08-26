# DE-01 Document Index

Dependency / Risk Evidence(Data Engineering) 역할 폴더다.  
**문서·픽스처·계약은 여기**, 실행 Java는 Spring sourceSet 안 `de` 패키지에 둔다.

## 폴더 구조

```text
de/
├── DE-01-document-index.md
├── DE-02-dependency-parser.md
├── contracts/
│   └── risk-evidence.md          ← AI evidence / recommendation 계약
└── fixtures/                     ← 파서 샘플 매니페스트 (클릭해서 바로 확인)
    ├── build.gradle.sample
    ├── pom.xml.sample
    └── package.json.sample

spring/src/main/verification/de/  ← 실행 코드 (빌드 sourceSet)
├── dependency/                   ← Gradle/Maven/npm 파서
└── risk/                         ← Evidence / AI enum
```

## 1. 문서

| 문서 | 설명 |
| --- | --- |
| `DE-01-document-index.md` | 본 문서 — DE 폴더 인덱스 |
| `DE-02-dependency-parser.md` | Manifest 파서 계약과 코드 위치 |
| `contracts/risk-evidence.md` | Risk evidence / AI recommendation 계약 |
| `fixtures/*` | 파서가 읽는 샘플 매니페스트 |

## 2. 실행 코드 (Spring sourceSet)

> Gradle sourceSet이 `src/main/verification`으로 고정돼 있어 `.java`는 최상위 `de/`로
> 옮기면 빌드가 깨진다. 프레임워크 소스 루트 **안에서** `de` 패키지로 모았다.

### Dependency parsers

| 파일 | 설명 |
| --- | --- |
| `../spring/src/main/verification/de/dependency/DependencyManifestParser.java` | 파서 인터페이스 (`supports` / `parse`) |
| `../spring/src/main/verification/de/dependency/GradleDependencyParser.java` | `build.gradle` / `.kts` |
| `../spring/src/main/verification/de/dependency/MavenPomDependencyParser.java` | `pom.xml` |
| `../spring/src/main/verification/de/dependency/PackageJsonDependencyParser.java` | `package.json` |
| `../spring/src/main/verification/de/dependency/DependencyExtractor.java` | 매니페스트 목록 → 좌표 dedupe |
| `../spring/src/main/verification/de/dependency/PackageCoordinate.java` | ecosystem/name/version 좌표 |
| `../spring/src/main/verification/de/dependency/DependencyManifest.java` | path + content 입력 |
| `../spring/src/test/verification/de/dependency/DependencyParserTest.java` | 파서 단위 테스트 |

### Risk evidence 계약 타입

| 파일 | 설명 |
| --- | --- |
| `../spring/src/main/verification/de/risk/AiConfidence.java` | AI confidence enum |
| `../spring/src/main/verification/de/risk/AiOutputStatus.java` | AI output status |
| `../spring/src/main/verification/de/risk/AiRecommendation.java` | USE/FIX/IGNORE 권고 |
| `../spring/src/main/verification/de/risk/EvidenceSource.java` | OSV/NVD/… 출처 |
| `../spring/src/main/verification/de/risk/EvidenceStatus.java` | evidence status |

분석 오케스트레이션(Controller/Service/AI client)은 `analysis/`에 유지하고,
파서·증거 계약 타입만 `de/`로 분리했다.

## 3. 관련 DB 마이그레이션

| 파일 | 설명 |
| --- | --- |
| `../db/migration/V6__vulnerability_risk_evidence.sql` | vulnerability / risk evidence 스키마 |
| `../db/migration/V7__ai_risk_evidence_contract.sql` | AI risk evidence 계약 확장 |

DB 인덱스는 `../db/DB-03-migration-index.md`를 본다.

## 4. 관련 AI 서비스

| 경로 | 설명 |
| --- | --- |
| `../ai-service/app/services/dependency_extractor.py` | Python 측 dependency 추출 |
| `../ai-service/app/services/risk_analyzer.py` | 리스크 분석 |
