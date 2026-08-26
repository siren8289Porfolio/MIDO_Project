package com.mido.verification.de.dependency;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class DependencyParserTest {

    @Test
    void parsesGradleStringAndMapNotation() {
        String content = """
                dependencies {
                    implementation("org.springframework:spring-web:6.1.6")
                    testImplementation 'org.junit.jupiter:junit-jupiter:5.10.2'
                    runtimeOnly group: 'org.postgresql', name: 'postgresql', version: '42.7.3'
                    implementation("com.example:dynamic:${version}")
                }
                """;

        List<PackageCoordinate> coordinates = new GradleDependencyParser()
                .parse(new DependencyManifest("build.gradle", content));

        assertThat(coordinates)
                .extracting(PackageCoordinate::name)
                .containsExactly(
                        "org.springframework:spring-web",
                        "org.junit.jupiter:junit-jupiter",
                        "org.postgresql:postgresql"
                );
        assertThat(coordinates)
                .extracting(PackageCoordinate::version)
                .containsExactly("6.1.6", "5.10.2", "42.7.3");
    }

    @Test
    void parsesMavenPomDependenciesWithConcreteVersionsOnly() {
        String content = """
                <project>
                  <dependencies>
                    <dependency>
                      <groupId>com.fasterxml.jackson.core</groupId>
                      <artifactId>jackson-databind</artifactId>
                      <version>2.17.0</version>
                    </dependency>
                    <dependency>
                      <groupId>org.example</groupId>
                      <artifactId>dynamic</artifactId>
                      <version>${example.version}</version>
                    </dependency>
                  </dependencies>
                </project>
                """;

        List<PackageCoordinate> coordinates = new MavenPomDependencyParser()
                .parse(new DependencyManifest("pom.xml", content));

        assertThat(coordinates).singleElement().satisfies(coordinate -> {
            assertThat(coordinate.ecosystem()).isEqualTo("Maven");
            assertThat(coordinate.name()).isEqualTo("com.fasterxml.jackson.core:jackson-databind");
            assertThat(coordinate.version()).isEqualTo("2.17.0");
        });
    }

    @Test
    void parsesPackageJsonDependencies() {
        String content = """
                {
                  "dependencies": {
                    "next": "14.2.3",
                    "react": "^18.3.1"
                  },
                  "devDependencies": {
                    "typescript": "~5.5.4",
                    "local-package": "file:../local"
                  }
                }
                """;

        List<PackageCoordinate> coordinates = new PackageJsonDependencyParser(new ObjectMapper())
                .parse(new DependencyManifest("web/package.json", content));

        assertThat(coordinates)
                .extracting(PackageCoordinate::name)
                .containsExactly("next", "react", "typescript");
        assertThat(coordinates)
                .extracting(PackageCoordinate::version)
                .containsExactly("14.2.3", "18.3.1", "5.5.4");
    }

    @Test
    void extractorDeduplicatesAcrossManifests() {
        DependencyExtractor extractor = new DependencyExtractor(List.of(
                new GradleDependencyParser(),
                new PackageJsonDependencyParser(new ObjectMapper())
        ));

        List<PackageCoordinate> coordinates = extractor.extract(List.of(
                new DependencyManifest("spring/build.gradle.kts", "dependencies { implementation(\"org.springframework:spring-web:6.1.6\") }"),
                new DependencyManifest("other/build.gradle", "dependencies { implementation 'org.springframework:spring-web:6.1.6' }"),
                new DependencyManifest("web/package.json", "{\"dependencies\":{\"next\":\"14.2.3\"}}")
        ));

        assertThat(coordinates)
                .extracting(coordinate -> coordinate.ecosystem() + ":" + coordinate.name() + ":" + coordinate.version())
                .containsExactly("Maven:org.springframework:spring-web:6.1.6", "npm:next:14.2.3");
    }
}
