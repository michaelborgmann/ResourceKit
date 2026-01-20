//
//  JSONValueTests.swift
//  ResourceKit
//
//  Created by Michael Borgmann on 20/01/2026.
//

import Testing
@testable import ResourceKit
import Foundation

struct JSONValueTests {

    // MARK: - Helpers

    private func decodeJSONValue(_ json: String) throws -> JSONValue {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(JSONValue.self, from: data)
    }

    private func roundTrip(_ value: JSONValue) throws -> JSONValue {
        let data = try JSONEncoder().encode(value)
        return try JSONDecoder().decode(JSONValue.self, from: data)
    }

    // MARK: - Decode basics

    @Test
    func decode_null() throws {
        let value = try decodeJSONValue("null")
        #expect(value == .null)
    }

    @Test
    func decode_bool() throws {
        #expect(try decodeJSONValue("true") == .bool(true))
        #expect(try decodeJSONValue("false") == .bool(false))
    }

    @Test
    func decode_number_isDouble() throws {
        let value = try decodeJSONValue("42")
        guard case .number(let n) = value else {
            Issue.record("Expected .number, got \(value)")
            return
        }
        #expect(n == 42.0)
    }

    @Test
    func decode_string() throws {
        let value = try decodeJSONValue(#""hi""#)
        #expect(value == .string("hi"))
    }

    @Test
    func decode_array() throws {
        let value = try decodeJSONValue(#"[1, true, "x", null]"#)
        #expect(value == .array([.number(1), .bool(true), .string("x"), .null]))
    }

    @Test
    func decode_object() throws {
        let value = try decodeJSONValue(#"{"a": 1, "b": "x"}"#)
        #expect(value == .object(["a": .number(1), "b": .string("x")]))
    }

    // MARK: - Round-trip stability

    @Test
    func roundTrip_preservesStructure() throws {
        let original: JSONValue = .object([
            "id": .string("abc"),
            "count": .number(3),
            "flags": .array([.bool(true), .null]),
            "meta": .object(["x": .string("y")])
        ])

        let decoded = try roundTrip(original)
        #expect(decoded == original)
    }

    // MARK: - Typed decode helper

    @Test
    func decode_typedObjectPayload() throws {
        struct Payload: Decodable, Equatable {
            let lesson: Int
            let title: Title

            struct Title: Decodable, Equatable {
                let text: String
            }
        }

        let value = try decodeJSONValue(#"{"lesson": 1, "title": {"text": "马马虎虎"}}"#)
        let payload = try value.decode(Payload.self)

        #expect(payload == Payload(lesson: 1, title: .init(text: "马马虎虎")))
    }

    @Test
    func decode_typedArrayPayload() throws {
        struct Item: Decodable, Equatable {
            let id: String
        }

        let value = try decodeJSONValue(#"[{"id":"1"},{"id":"2"}]"#)
        let items = try value.decode([Item].self)

        #expect(items == [Item(id: "1"), Item(id: "2")])
    }

    @Test
    func decode_typedPayload_failure() throws {
        struct Payload: Decodable {
            let missingKey: String
        }

        let value = try decodeJSONValue(#"{"otherKey": "x"}"#)

        do {
            let _: Payload = try value.decode(Payload.self)
            Issue.record("Expected DecodingError")
        } catch {
            #expect(error is DecodingError)
        }
    }
}

