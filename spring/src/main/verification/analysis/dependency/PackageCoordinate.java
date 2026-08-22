package com.mido.verification.analysis.dependency;

import java.util.Objects;

public record PackageCoordinate(
        String ecosystem,
        String name,
        String version,
        String manifestPath,
        String dependencyGroup
) {
    public PackageCoordinate {
        ecosystem = requireText(ecosystem, "ecosystem");
        name = requireText(name, "name");
        version = requireText(version, "version");
        manifestPath = requireText(manifestPath, "manifestPath");
        dependencyGroup = normalizeOptional(dependencyGroup);
    }

    private static String requireText(String value, String field) {
        if (value == null || value.isBlank()) {
            throw new IllegalArgumentException(field + " is required");
        }
        return value.trim();
    }

    private static String normalizeOptional(String value) {
        if (value == null || value.isBlank()) {
            return null;
        }
        return value.trim();
    }

    public String osvPackageName() {
        return Objects.requireNonNull(name);
    }
}
