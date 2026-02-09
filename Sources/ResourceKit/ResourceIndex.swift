//
//  ResourceIndex.swift
//  ResourceKit
//
//  Created by Michael Borgmann on 14/01/2026.
//

import Foundation

// MARK: - Resource Index File Model

/// A normalized manifest describing a collection of resources.
///
/// `ResourceIndex` is a small, stable schema for listing resources and
/// describing how to locate them. It is intended to be:
///
/// - Simple and predictable
/// - Independent of any concrete content format
/// - Suitable for previews, navigation, and loading decisions
///
/// The index intentionally does **not** attempt to mirror arbitrary JSON.
/// Instead, it exposes a strongly typed core schema and one explicit extension
/// point via `ResourceIndex.Item.payload`.
///
/// Typical use cases include:
/// - Listing items in a content set (e.g. chapters, cards, levels, tracks)
/// - Showing lightweight previews before loading full resources
/// - Driving navigation or sequencing logic
///
/// The actual resource data is referenced indirectly via `ResourceIndex.Item.target`.
public struct ResourceIndex: Codable, Sendable {
    
    /// Schema version of the index file.
    public let schema: Int
    
    /// Human-readable title of the resource collection.
    public let title: String
    
    /// Stable identifier for the resource set.
    public let setId: String
    
    /// Version string of the index contents.
    public let version: String
    
    /// The list of indexed resource entries.
    public let items: [Item]
    
    /// Loads a `ResourceIndex` from a bundled JSON file.
    ///
    /// - Parameters:
    ///   - fileName: The name of the JSON file (without extension).
    ///   - bundle: The bundle containing the resource. Defaults to `.main`.
    /// - Returns: A decoded `ResourceIndex`.
    /// - Throws: A `ResourceError` if loading or decoding fails.
    public static func load(
        fileName: String,
        in bundle: Bundle = .main
    ) throws -> Self {
        try JSON.load(name: fileName, in: bundle)
    }
}

// MARK: - Index Item

public extension ResourceIndex {
    
    /// A normalized entry describing a single resource within a `ResourceIndex`.
    ///
    /// `Item` represents a **strict, schema-owned view** of a resource entry.
    /// It intentionally decodes only known fields and ignores unknown ones.
    ///
    /// Use `payload` for lightweight, format-specific metadata (for example,
    /// a display title, a numeric level, a category, or tags) when you **own**
    /// the index format or normalize data into it.
    ///
    /// ---
    /// ### Future Extension (Not Implemented)
    ///
    /// A common extension for normalized manifests is to preserve unknown keys
    /// when loading *foreign* or *third-party* JSON formats.
    ///
    /// Implementation sketch:
    /// 1. Add `dynamicFields: [String: JSONValue]?`.
    /// 2. Implement a custom `init(from:)` for `Item`.
    /// 3. Decode known keys (`id`, `order`, `target`, `payload`) normally.
    /// 4. Decode the full item object using a `DynamicCodingKey` into
    ///    `[String: JSONValue]`.
    /// 5. Remove known keys and store the remainder in `dynamicFields`.
    ///
    /// This follows the standard “capture unknown keys” Codable pattern and
    /// enables lossless loading of foreign or legacy manifests.
    struct Item: Codable, Sendable, Identifiable {
        
        /// Stable identifier of the resource entry.
        public let id: String
        
        /// Optional ordering hint within the index.
        public let order: Int?
        
        /// Reference describing how to locate or load the resource.
        public let target: Target
        
        /// Schema-owned extension payload for lightweight metadata.
        ///
        /// This is the explicit extension point for data you **own** or
        /// normalize into the index schema.
        ///
        /// Example uses include:
        /// - a display title
        /// - an estimated duration or difficulty
        /// - a category or tags
        /// - a small preview object used for lists
        public let payload: JSONValue?
        
        /// Decodes the item's `payload` into a concrete type.
        ///
        /// `payload` is stored as a type-erased `JSONValue` to keep
        /// `ResourceIndex` format-agnostic. This helper allows callers to
        /// decode that value into a strongly typed model when needed.
        ///
        /// - Parameters:
        ///   - type: The expected payload type.
        ///   - decoder: The `JSONDecoder` to use. Defaults to a new instance.
        /// - Returns: The decoded payload, or `nil` if the item has no payload.
        /// - Throws: A `DecodingError` if the payload exists but does not match
        ///   the expected type.
        public func decodePayload<T: Decodable>(_ type: T.Type, decoder: JSONDecoder = .init()) throws -> T? {
            guard let payload else { return nil }
            return try payload.decode(T.self, using: decoder)
        }
    }
    
    /// A reference describing how to locate a resource listed in the index.
    ///
    /// `Target` does not prescribe *how* the resource is loaded. It only
    /// provides a structured reference that a higher-level loading layer can
    /// interpret (for example by mapping `ref` strings to bundle paths or
    /// storage identifiers).
    struct Target: Codable, Sendable, Hashable {
        
        /// The kind of target reference.
        public let kind: Kind
        
        /// A reference string interpreted by the resource loading layer.
        public let ref: String
        
        /// Creates a new target reference.
        public init(kind: Kind, ref: String) {
            self.kind = kind
            self.ref = ref
        }
        
        /// Supported target kinds.
        public enum Kind: String, Codable, Sendable, Hashable {
            
            /// A reference to a loadable resource.
            case resource
        }
    }
}
