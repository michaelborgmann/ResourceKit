//
//  ResourceIndexTests.swift
//  ResourceKit
//
//  Created by Michael Borgmann on 20/01/2026.
//

import Testing
@testable import ResourceKit
import Foundation

struct ResourceIndexTests {

    @Test
    func decode_success_minimal() throws {
        let json = #"""
        {
          "schema": 1,
          "title": "Example Set",
          "setId": "example-set",
          "version": "0.1.0",
          "items": [
            {
              "id": "item-001",
              "order": 1,
              "payload": { "preview": "Hello" },
              "target": { "kind": "resource", "ref": "resources/item-001" }
            }
          ]
        }
        """#

        let data = Data(json.utf8)
        let index = try JSONDecoder().decode(ResourceIndex.self, from: data)

        #expect(index.schema == 1)
        #expect(index.title == "Example Set")
        #expect(index.setId == "example-set")
        #expect(index.version == "0.1.0")
        #expect(index.items.count == 1)

        let item = index.items[0]
        #expect(item.id == "item-001")
        #expect(item.order == 1)
        #expect(item.target.kind == .resource)
        #expect(item.target.ref == "resources/item-001")

        // payload is type-erased, but we can still assert structure
        #expect(item.payload == .object(["preview": .string("Hello")]))
    }

    @Test
    func decode_ignoresUnknownKeysInItem() throws {
        let json = #"""
        {
          "schema": 1,
          "title": "Example Set",
          "setId": "example-set",
          "version": "0.1.0",
          "items": [
            {
              "id": "item-001",
              "order": 1,
              "lesson": 123,
              "difficulty": "easy",
              "payload": { "preview": "Hello" },
              "target": { "kind": "resource", "ref": "resources/item-001" }
            }
          ]
        }
        """#

        let data = Data(json.utf8)
        let index = try JSONDecoder().decode(ResourceIndex.self, from: data)

        // If decoding succeeds, unknown keys were ignored (current intended behavior).
        #expect(index.items.count == 1)

        // And the known fields still decode correctly:
        let item = index.items[0]
        #expect(item.id == "item-001")
        #expect(item.order == 1)
        #expect(item.payload == .object(["preview": .string("Hello")]))
    }

    @Test
    func decode_failure_missingRequiredKey() throws {
        let json = #"""
        {
          "schema": 1,
          "title": "Example Set",
          "version": "0.1.0",
          "items": []
        }
        """# // missing setId

        let data = Data(json.utf8)

        do {
            _ = try JSONDecoder().decode(ResourceIndex.self, from: data)
            Issue.record("Expected DecodingError due to missing required key.")
        } catch {
            #expect(error is DecodingError)
        }
    }

    @Test
    func decodePayload_returnsNil_whenNoPayload() throws {
        let item = ResourceIndex.Item(
            id: "item-001",
            order: 1,
            target: .init(kind: .resource, ref: "resources/item-001"),
            payload: nil
        )

        struct Payload: Decodable { let title: String }

        let decoded = try item.decodePayload(Payload.self)
        #expect(decoded == nil)
    }

    @Test
    func decodePayload_decodes_whenPayloadMatches() throws {
        let item = ResourceIndex.Item(
            id: "item-001",
            order: 1,
            target: .init(kind: .resource, ref: "resources/item-001"),
            payload: .object([
                "title": .string("Hello"),
                "difficulty": .number(1)
            ])
        )

        struct Payload: Decodable, Equatable {
            let title: String
            let difficulty: Int
        }

        let decoded = try item.decodePayload(Payload.self)
        #expect(decoded == Payload(title: "Hello", difficulty: 1))
    }

    @Test
    func decodePayload_throws_whenPayloadMismatches() throws {
        let item = ResourceIndex.Item(
            id: "item-001",
            order: 1,
            target: .init(kind: .resource, ref: "resources/item-001"),
            payload: .object([
                "title": .number(123) // should be String
            ])
        )

        struct Payload: Decodable { let title: String }

        do {
            _ = try item.decodePayload(Payload.self)
            Issue.record("Expected DecodingError")
        } catch {
            #expect(error is DecodingError)
        }
    }
}
