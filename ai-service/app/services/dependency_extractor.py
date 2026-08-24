from __future__ import annotations

import re
from typing import Iterable

from app.schemas.risk import DependencyCoordinate


PACKAGE_JSON_PATTERN = re.compile(
    r'"([@a-zA-Z0-9._/-]+)"\s*:\s*"([^"]+)"',
    re.MULTILINE,
)
GRADLE_PATTERN = re.compile(
    r"(?:implementation|api|compileOnly|runtimeOnly)\s+['\"]([^:'\"]+):([^:'\"]+):([^:'\"]+)['\"]"
)
MAVEN_PATTERN = re.compile(
    r"<groupId>([^<]+)</groupId>\s*<artifactId>([^<]+)</artifactId>\s*<version>([^<]+)</version>",
    re.DOTALL,
)


def extract_dependencies_from_code(code: str | None) -> list[DependencyCoordinate]:
    if not code:
        return []

    path_hint = _guess_manifest_path(code)
    if path_hint.endswith("package.json"):
        return _extract_npm(code)
    if path_hint.endswith("build.gradle") or path_hint.endswith("build.gradle.kts"):
        return _extract_gradle(code)
    if path_hint.endswith("pom.xml"):
        return _extract_maven(code)
    return []


def merge_dependencies(
    explicit: Iterable[DependencyCoordinate],
    from_code: Iterable[DependencyCoordinate],
) -> list[DependencyCoordinate]:
    merged: dict[str, DependencyCoordinate] = {}
    for coordinate in list(explicit) + list(from_code):
        key = f"{coordinate.ecosystem}:{coordinate.name}:{coordinate.version}"
        merged.setdefault(key, coordinate)
    return list(merged.values())


def _guess_manifest_path(code: str) -> str:
    first_line = code.strip().splitlines()[0] if code.strip() else ""
    if first_line.startswith("# path:"):
        return first_line.split(":", 1)[1].strip()
    if '"dependencies"' in code:
        return "package.json"
    if "implementation" in code or "plugins {" in code:
        return "build.gradle.kts"
    if "<project" in code:
        return "pom.xml"
    return "unknown"


def _extract_npm(code: str) -> list[DependencyCoordinate]:
    coordinates: list[DependencyCoordinate] = []
    for name, version in PACKAGE_JSON_PATTERN.findall(code):
        if name in {"dependencies", "devDependencies", "peerDependencies"}:
            continue
        coordinates.append(DependencyCoordinate(ecosystem="npm", name=name, version=_normalize_version(version)))
    return coordinates


def _extract_gradle(code: str) -> list[DependencyCoordinate]:
    return [
        DependencyCoordinate(ecosystem="Maven", name=f"{group}:{artifact}", version=_normalize_version(version))
        for group, artifact, version in GRADLE_PATTERN.findall(code)
    ]


def _extract_maven(code: str) -> list[DependencyCoordinate]:
    return [
        DependencyCoordinate(ecosystem="Maven", name=f"{group}:{artifact}", version=_normalize_version(version))
        for group, artifact, version in MAVEN_PATTERN.findall(code)
    ]


def _normalize_version(version: str) -> str:
    return version.removeprefix("^").removeprefix("~").strip()
