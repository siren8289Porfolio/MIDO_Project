package com.mido.verification.de.dependency;

import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Component
public class GradleDependencyParser implements DependencyManifestParser {

    private static final Pattern STRING_NOTATION = Pattern.compile(
            "\\b([A-Za-z][A-Za-z0-9_]*)\\s*\\(?\\s*[\"']([^:\"']+):([^:\"']+):([^:\"']+)[\"']\\s*\\)?"
    );
    private static final Pattern MAP_NOTATION = Pattern.compile(
            "\\b([A-Za-z][A-Za-z0-9_]*)\\s*\\(?\\s*group\\s*:\\s*[\"']([^\"']+)[\"']\\s*,\\s*name\\s*:\\s*[\"']([^\"']+)[\"']\\s*,\\s*version\\s*:\\s*[\"']([^\"']+)[\"']\\s*\\)?"
    );

    @Override
    public boolean supports(String manifestPath) {
        return manifestPath.endsWith("build.gradle") || manifestPath.endsWith("build.gradle.kts");
    }

    @Override
    public List<PackageCoordinate> parse(DependencyManifest manifest) {
        List<PackageCoordinate> coordinates = new ArrayList<>();
        collectStringNotation(manifest, coordinates);
        collectMapNotation(manifest, coordinates);
        return coordinates;
    }

    private void collectStringNotation(DependencyManifest manifest, List<PackageCoordinate> coordinates) {
        Matcher matcher = STRING_NOTATION.matcher(manifest.content());
        while (matcher.find()) {
            String configuration = matcher.group(1);
            String group = matcher.group(2);
            String artifact = matcher.group(3);
            String version = matcher.group(4);
            if (isDependencyConfiguration(configuration) && isConcreteVersion(version)) {
                coordinates.add(new PackageCoordinate(
                        "Maven",
                        group + ":" + artifact,
                        version,
                        manifest.path(),
                        configuration
                ));
            }
        }
    }

    private void collectMapNotation(DependencyManifest manifest, List<PackageCoordinate> coordinates) {
        Matcher matcher = MAP_NOTATION.matcher(manifest.content());
        while (matcher.find()) {
            String configuration = matcher.group(1);
            String group = matcher.group(2);
            String artifact = matcher.group(3);
            String version = matcher.group(4);
            if (isDependencyConfiguration(configuration) && isConcreteVersion(version)) {
                coordinates.add(new PackageCoordinate(
                        "Maven",
                        group + ":" + artifact,
                        version,
                        manifest.path(),
                        configuration
                ));
            }
        }
    }

    private boolean isDependencyConfiguration(String configuration) {
        return configuration.endsWith("Implementation")
                || configuration.endsWith("Api")
                || configuration.equals("implementation")
                || configuration.equals("api")
                || configuration.equals("compileOnly")
                || configuration.equals("runtimeOnly")
                || configuration.equals("annotationProcessor");
    }

    private boolean isConcreteVersion(String version) {
        return !version.contains("$") && !version.contains("{") && !version.isBlank();
    }
}
