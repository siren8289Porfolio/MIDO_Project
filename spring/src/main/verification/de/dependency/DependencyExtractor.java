package com.mido.verification.de.dependency;

import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class DependencyExtractor {

    private final List<DependencyManifestParser> parsers;

    public DependencyExtractor(List<DependencyManifestParser> parsers) {
        this.parsers = parsers;
    }

    public List<PackageCoordinate> extract(List<DependencyManifest> manifests) {
        Map<String, PackageCoordinate> deduplicated = new LinkedHashMap<>();

        for (DependencyManifest manifest : manifests) {
            DependencyManifestParser parser = findParser(manifest.path());
            for (PackageCoordinate coordinate : parser.parse(manifest)) {
                deduplicated.putIfAbsent(deduplicationKey(coordinate), coordinate);
            }
        }

        return new ArrayList<>(deduplicated.values());
    }

    private DependencyManifestParser findParser(String manifestPath) {
        return parsers.stream()
                .filter(parser -> parser.supports(manifestPath))
                .findFirst()
                .orElseThrow(() -> new IllegalArgumentException("Unsupported dependency manifest: " + manifestPath));
    }

    private String deduplicationKey(PackageCoordinate coordinate) {
        return coordinate.ecosystem() + ":" + coordinate.name() + ":" + coordinate.version();
    }
}
