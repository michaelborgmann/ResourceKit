//
//  ResourcePackageTests.swift
//  ResourceKit
//
//  Created by Michael Borgmann on 09/02/2026.
//

import Foundation
import Testing
@testable import ResourceKit

@Suite("ResourcePackage decoding")
struct ResourcePackageTests {

    @Test("Decodes a minimal package manifest")
    func decodesMinimalManifest() throws {
        let json = """
        {
          "schema": 1,
          "packageId": "package-identifier",
          "version": "0.1.0",
          "path": "relative/path",
          "resources": [
            { "key": "index", "file": "index.json" },
            { "key": "category/identifier-001", "file": "001.json" },
            { "key": "category/identifier-002", "file": "002.json" }
          ]
        }
        """

        let data = try #require(json.data(using: .utf8))
        let pkg = try JSONDecoder().decode(ResourcePackage.self, from: data)

        #expect(pkg.schema == 1)
        #expect(pkg.packageId == "package-identifier")
        #expect(pkg.version == "0.1.0")
        #expect(pkg.path == "relative/path")
        #expect(pkg.resources.count == 3)

        #expect(pkg.resources[0].key == "index")
        #expect(pkg.resources[0].file == "index.json")
    }

    @Test("Ignores unknown fields for forward compatibility")
    func ignoresUnknownFields() throws {
        let json = """
        {
          "schema": 1,
          "packageId": "package-identifier",
          "version": "0.1.0",
          "path": "relative/path",
          "resources": [
            {
              "key": "index",
              "file": "index.json",
              "codec": "plain",
              "meta": { "note": "future field" }
            }
          ],
          "unexpectedTopLevel": true
        }
        """

        let data = try #require(json.data(using: .utf8))
        let pkg = try JSONDecoder().decode(ResourcePackage.self, from: data)

        #expect(pkg.resources.count == 1)
        #expect(pkg.resources[0].key == "index")
        #expect(pkg.resources[0].file == "index.json")
    }

    @Test("Fails decoding when required fields are missing")
    func failsOnMissingRequiredFields() throws {
        let jsonMissingPath = """
        {
          "schema": 1,
          "packageId": "package-identifier",
          "version": "0.1.0",
          "resources": []
        }
        """

        let data = try #require(jsonMissingPath.data(using: .utf8))

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(ResourcePackage.self, from: data)
        }
    }

    @Test("Decodes absolute filesystem paths")
    func decodesAbsolutePath() throws {
        let json = """
        {
          "schema": 1,
          "packageId": "custom-course",
          "version": "0.1.0",
          "path": "/abosolute/path/custom-course",
          "resources": [
            { "key": "index", "file": "index.json" }
          ]
        }
        """

        let data = try #require(json.data(using: .utf8))
        let pkg = try JSONDecoder().decode(ResourcePackage.self, from: data)

        #expect(pkg.path.hasPrefix("/"))
    }

    @Test("Decodes remote URL paths")
    func decodesRemoteURLPath() throws {
        let json = """
        {
          "schema": 1,
          "packageId": "remote-course",
          "version": "0.1.0",
          "path": "https://example.com/packages/remote-course",
          "resources": [
            { "key": "index", "file": "index.json" }
          ]
        }
        """

        let data = try #require(json.data(using: .utf8))
        let pkg = try JSONDecoder().decode(ResourcePackage.self, from: data)

        let url = try #require(URL(string: pkg.path))
        #expect(url.scheme == "https")
        #expect(url.host == "example.com")
    }
}
