# DE-02 Dependency Parser

MIDO가 Verification 대상 저장소/파일에서 dependency 좌표를 추출하는 파서 계약이다.

## 1. 흐름

```text
DependencyManifest (path, content)
        ↓
DependencyManifestParser.supports(path)
        ↓
parse() → List<PackageCoordinate>
        ↓
DependencyExtractor (dedupe by ecosystem:name:version)
```

## 2. 지원 매니페스트

| Parser | 경로 패턴 | Ecosystem |
| --- | --- | --- |
| `GradleDependencyParser` | `build.gradle`, `build.gradle.kts` | maven |
| `MavenPomDependencyParser` | `pom.xml` | maven |
| `PackageJsonDependencyParser` | `package.json` | npm |

구체 버전만 수집하고, 변수/range만 있는 항목은 제외한다.

## 3. 코드 위치

Spring sourceSet 제약으로 실행 코드는 아래에 둔다.

```text
spring/src/main/verification/de/
├── dependency/     # parsers + extractor
└── risk/           # evidence / AI recommendation enums

spring/src/test/verification/de/
└── dependency/
    └── DependencyParserTest.java
```

패키지: `com.mido.verification.de.dependency`, `com.mido.verification.de.risk`

## 4. 다운스트림

- Spring `analysis` 계층이 AI 분석 요청 DTO에 `de.risk` 타입을 사용
- FastAPI `ai-service`가 별도 Python extractor로 유사 좌표를 추출
- DB 계약: `V6` / `V7` risk evidence 테이블 (`../db/DB-03-migration-index.md`)
