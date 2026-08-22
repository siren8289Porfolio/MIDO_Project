package com.mido.verification.analysis.dependency;

public record DependencyManifest(
        String path,
        String content
) {
    public DependencyManifest {
        if (path == null || path.isBlank()) {
            throw new IllegalArgumentException("manifest path is required");
        }
        if (content == null) {
            throw new IllegalArgumentException("manifest content is required");
        }
    }
}
