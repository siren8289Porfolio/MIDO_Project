package com.mido.verification.de.dependency;

import java.util.List;

public interface DependencyManifestParser {

    boolean supports(String manifestPath);

    List<PackageCoordinate> parse(DependencyManifest manifest);
}
