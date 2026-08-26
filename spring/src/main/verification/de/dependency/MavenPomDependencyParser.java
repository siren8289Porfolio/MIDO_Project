package com.mido.verification.de.dependency;

import org.springframework.stereotype.Component;
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.Node;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

import javax.xml.XMLConstants;
import javax.xml.parsers.DocumentBuilderFactory;
import java.io.StringReader;
import java.util.ArrayList;
import java.util.List;

@Component
public class MavenPomDependencyParser implements DependencyManifestParser {

    @Override
    public boolean supports(String manifestPath) {
        return manifestPath.endsWith("pom.xml");
    }

    @Override
    public List<PackageCoordinate> parse(DependencyManifest manifest) {
        try {
            DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
            factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true);
            factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_DTD, "");
            factory.setAttribute(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "");

            Document document = factory.newDocumentBuilder()
                    .parse(new InputSource(new StringReader(manifest.content())));
            NodeList dependencies = document.getElementsByTagName("dependency");
            List<PackageCoordinate> coordinates = new ArrayList<>();

            for (int i = 0; i < dependencies.getLength(); i++) {
                Node node = dependencies.item(i);
                if (node instanceof Element dependency) {
                    String groupId = childText(dependency, "groupId");
                    String artifactId = childText(dependency, "artifactId");
                    String version = childText(dependency, "version");
                    String scope = childText(dependency, "scope");

                    if (hasText(groupId) && hasText(artifactId) && isConcreteVersion(version)) {
                        coordinates.add(new PackageCoordinate(
                                "Maven",
                                groupId + ":" + artifactId,
                                version,
                                manifest.path(),
                                hasText(scope) ? scope : "compile"
                        ));
                    }
                }
            }

            return coordinates;
        } catch (Exception e) {
            throw new IllegalArgumentException("Invalid Maven pom manifest: " + manifest.path(), e);
        }
    }

    private String childText(Element element, String tagName) {
        NodeList nodes = element.getElementsByTagName(tagName);
        if (nodes.getLength() == 0) {
            return null;
        }
        return nodes.item(0).getTextContent().trim();
    }

    private boolean isConcreteVersion(String version) {
        return hasText(version) && !version.contains("$") && !version.contains("{");
    }

    private boolean hasText(String value) {
        return value != null && !value.isBlank();
    }
}
