//
//  JSON.swift
//  ResourceKit
//
//  Created by Michael Borgmann on 28/08/2025.
//

import Foundation

/// A utility for decoding and loading JSON resources.
///
/// The `JSON` type provides convenience methods for decoding `Data` into Swift models
/// and for loading and decoding JSON files packaged in an app or framework bundle.
public enum JSON {
    
    /// Decodes JSON data into a `Decodable` model.
    ///
    /// Use this method when you already have JSON data in memory and want to convert it
    /// into a strongly-typed Swift value.
    ///
    /// ```swift
    /// struct User: Decodable { let name: String }
    /// let data = #"{"name": "Michael"}"#.data(using: .utf8)!
    /// let user: User = try JSON.decode(data: data)
    /// print(user.name) // "Michael"
    /// ```
    ///
    /// - Parameter data: The raw JSON data to decode.
    /// - Throws: ``ResourceError/jsonDecodingFailed(underlying:)``
    ///   if decoding fails, wrapping the underlying `DecodingError`.
    /// - Returns: A decoded instance of type `T`.
    public static func decode<T: Decodable>(data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw ResourceError.jsonDecodingFailed(underlying: error)
        }
    }
    
    /// Loads and decodes a JSON file from a bundle.
    ///
    /// This is a convenience method that finds a file in the specified bundle,
    /// loads its contents, and decodes it into a Swift model.
    ///
    /// ```swift
    /// struct Config: Decodable { let apiKey: String }
    /// let config: Config = try JSON.load(name: "AppConfig")
    /// print(config.apiKey)
    /// ```
    ///
    /// - Parameters:
    ///   - name: The name of the JSON resource **without** its extension.
    ///   - ext: The file extension. Defaults to `"json"`.
    ///   - bundle: The bundle to search for the resource. Defaults to `.main`.
    /// - Throws:
    ///   - ``ResourceError/resourceNotFound(name:ext:)``
    ///     if the JSON file could not be found.
    ///   - ``ResourceError/dataLoadingFailed(url:underlying:)``
    ///     if the file could not be read.
    ///   - ``ResourceError/jsonDecodingFailed(underlying:)``
    ///     if the JSON could not be decoded.
    /// - Returns: A decoded instance of type `T`.
    public static func load<T: Decodable>(name: String, ext: String = "json", in bundle: Bundle = .main) throws -> T {
        let url = try Resource.url(name: name, ext: ext, in: bundle)
        let data = try Resource.data(for: url)
        return try JSON.decode(data: data)
    }
}
