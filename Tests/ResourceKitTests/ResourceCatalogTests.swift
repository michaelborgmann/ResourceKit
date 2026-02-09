//
//  ResourceCatalogTests.swift
//  ResourceKit
//
//  Created by Michael Borgmann on 09/02/2026.
//

import Foundation
import Testing
@testable import ResourceKit

@Suite("ResourceCatalog decoding")
struct ResourceCatalogTests {

    @Test("Decodes a minimal catalog")
    func decodesMinimalCatalog() throws {
        let json = """
        {
          "schema": 1,
          "catalogId": "main",
          "version": "0.1.0",
          "packages": [
            { "id": "packageA", "path": "path/to/packageA" },
            { "id": "packageB", "path": "path/to/packageB" }
          ]
        }
        """

        let data = try #require(json.data(using: .utf8))
        let catalog = try JSONDecoder().decode(ResourceCatalog.self, from: data)

        #expect(catalog.schema == 1)
        #expect(catalog.catalogId == "main")
        #expect(catalog.version == "0.1.0")
        #expect(catalog.packages.count == 2)

        #expect(catalog.packages[0].id == "packageA")
        #expect(catalog.packages[0].path == "path/to/packageA")
    }

    @Test("Decodes absolute and remote package paths")
    func decodesMixedPathForms() throws {
        let json = """
        {
          "schema": 1,
          "catalogId": "mixed",
          "version": "0.1.0",
          "packages": [
            { "id": "bundled", "path": "path/inside/bundle" },
            { "id": "disk", "path": "/path/on/disk" },
            { "id": "remote", "path": "https://example.com/remote" }
          ]
        }
        """

        let data = try #require(json.data(using: .utf8))
        let catalog = try JSONDecoder().decode(ResourceCatalog.self, from: data)

        #expect(catalog.packages.count == 3)

        #expect(catalog.packages[0].path.hasPrefix("path/"))
        #expect(catalog.packages[1].path.hasPrefix("/"))

        let remoteURL = try #require(URL(string: catalog.packages[2].path))
        #expect(remoteURL.scheme == "https")
        #expect(remoteURL.host == "example.com")
    }

    @Test("Ignores unknown fields for forward compatibility")
    func ignoresUnknownFields() throws {
        let json = """
        {
          "schema": 1,
          "catalogId": "main",
          "version": "0.1.0",
          "packages": [
            {
              "id": "packageId",
              "path": "path/to/package",
              "tags": ["tag1", "tag2"],
              "meta": { "note": "future fields" }
            }
          ],
          "unexpectedTopLevel": true
        }
        """

        let data = try #require(json.data(using: .utf8))
        let catalog = try JSONDecoder().decode(ResourceCatalog.self, from: data)

        #expect(catalog.packages.count == 1)
        #expect(catalog.packages[0].id == "packageId")
        #expect(catalog.packages[0].path == "path/to/package")
    }

    @Test("Fails decoding when required fields are missing")
    func failsOnMissingRequiredFields() throws {
        let jsonMissingPackages = """
        {
          "schema": 1,
          "catalogId": "main",
          "version": "0.1.0"
        }
        """

        let data = try #require(jsonMissingPackages.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(ResourceCatalog.self, from: data)
        }
    }

    @Test("Decodes an empty package list")
    func decodesEmptyCatalog() throws {
        let json = """
        {
          "schema": 1,
          "catalogId": "empty",
          "version": "0.1.0",
          "packages": []
        }
        """

        let data = try #require(json.data(using: .utf8))
        let catalog = try JSONDecoder().decode(ResourceCatalog.self, from: data)

        #expect(catalog.packages.isEmpty)
    }
}
