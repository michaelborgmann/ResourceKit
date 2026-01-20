//
//  JSONValue.swift
//  ResourceKit
//
//  Created by Michael Borgmann on 20/01/2026.
//

import Foundation

/// A type-erased representation of any JSON value.
///
/// `JSONValue` is useful when working with partially known or dynamic JSON
/// structures, such as resource payloads, previews, or vendor-specific metadata.
///
/// It supports all standard JSON value types:
/// - `null`
/// - `bool`
/// - `number` (represented as `Double`)
/// - `string`
/// - `array`
/// - `object`
///
/// > Important:
/// > JSON numbers are decoded and stored as `Double`.
/// > Integer semantics are not preserved.
///
/// This type is `Codable`, `Sendable`, and `Hashable`, making it suitable for
/// use across concurrency boundaries and in SwiftUI collections.
public enum JSONValue: Codable, Sendable, Hashable {
    
    /// A JSON `null` value.
    case null
    
    /// A JSON boolean value.
    case bool(Bool)
    
    /// A JSON numeric value, represented as `Double`.
    case number(Double)
    
    /// A JSON string value.
    case string(String)
    
    /// A JSON array value.
    case array([JSONValue])
    
    /// A JSON object value.
    case object([String: JSONValue])
    
    /// Creates a `JSONValue` by decoding an arbitrary JSON value.
    ///
    /// The decoder attempts to decode the value in the following order:
    /// `null → Bool → Double → String → Array → Object`.
    ///
    /// - Parameter decoder: The decoder to read data from.
    /// - Throws: `DecodingError` if the value cannot be represented as a supported JSON type.
    public init(from decoder: any Decoder) throws {
        
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() { self = .null; return }
        if let value = try? container.decode(Bool.self) { self = .bool(value); return }
        if let value = try? container.decode(Double.self) { self = .number(value); return }
        if let value = try? container.decode(String.self) { self = .string(value); return }
        if let value = try? container.decode([JSONValue].self) { self = .array(value); return }
        if let value = try? container.decode([String: JSONValue].self) { self = .object(value); return }
        
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Unsupported JSON value."
        )
    }
    
    /// Encodes the JSON value into the given encoder.
    ///
    /// - Parameter encoder: The encoder to write data to.
    /// - Throws: An error if encoding fails.
    public func encode(to encoder: any Encoder) throws {
        
        var container = encoder.singleValueContainer()
        
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }
}

// MAKR: - Helpers

extension JSONValue {
    
    /// Decodes the JSON value into a concrete `Decodable` type.
    ///
    /// This is commonly used to decode typed payloads stored as `JSONValue`,
    /// such as resource previews or embedded metadata.
    ///
    /// Internally, the value is re-encoded to JSON data before decoding.
    ///
    /// - Parameters:
    ///   - type: The target type to decode.
    ///   - decoder: The `JSONDecoder` to use. Defaults to a new instance.
    /// - Returns: A decoded instance of the requested type.
    /// - Throws: An error if encoding or decoding fails.
    public func decode<T: Decodable>(
        _ type: T.Type,
        using decoder: JSONDecoder = .init()
    ) throws -> T {
        let data = try JSONEncoder().encode(self)
        return try decoder.decode(T.self, from: data)
    }
}
