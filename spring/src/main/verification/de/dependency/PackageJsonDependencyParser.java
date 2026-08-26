package com.mido.verification.de.dependency;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

@Component
public class PackageJsonDependencyParser implements DependencyManifestParser {

    private static final List<String> DEPENDENCY_GROUPS = List.of(
            "dependencies",
            "devDependencies",
            "peerDependencies",
            "optionalDependencies"
    );

    private final ObjectMapper objectMapper;

    public PackageJsonDependencyParser(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    @Override
    public boolean supports(String manifestPath) {
        return manifestPath.endsWith("package.json");
    }

    @Override
    public List<PackageCoordinate> parse(DependencyManifest manifest) {
        try {
            JsonNode root = objectMapper.readTree(manifest.content());
            List<PackageCoordinate> coordinates = new ArrayList<>();

            for (String dependencyGroup : DEPENDENCY_GROUPS) {
                JsonNode dependencies = root.path(dependencyGroup);
                if (!dependencies.isObject()) {
                    continue;
                }

                Iterator<Map.Entry<String, JsonNode>> fields = dependencies.fields();
                while (fields.hasNext()) {
                    Map.Entry<String, JsonNode> field = fields.next();
                    String version = field.getValue().asText();
                    if (isConcreteVersion(version)) {
                        coordinates.add(new PackageCoordinate(
                                "npm",
                                field.getKey(),
                                normalizeVersion(version),
                                manifest.path(),
                                dependencyGroup
                        ));
                    }
                }
            }

            return coordinates;
        } catch (Exception e) {
            throw new IllegalArgumentException("Invalid package.json manifest: " + manifest.path(), e);
        }
    }

    private boolean isConcreteVersion(String version) {
        return version != null
                && !version.isBlank()
                && !version.startsWith("workspace:")
                && !version.startsWith("file:")
                && !version.startsWith("git+")
                && !version.contains("||");
    }

    private String normalizeVersion(String version) {
        return version.strip()
                .replaceFirst("^[~^=v]+", "")
                .trim();
    }
}
