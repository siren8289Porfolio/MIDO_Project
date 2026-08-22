package com.mido.verification.analysis.dependency;

import java.util.List;

public interface DependencyManifestParser {

    boolean supports(String manifestPath);

    List<PackageCoordinate> parse(DependencyManifest manifest);
}
