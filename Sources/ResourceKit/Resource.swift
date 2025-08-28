//
//  Resource.swift
//  ResourceKit
//
//  Created by Michael Borgmann on 28/08/2025.
//

import Foundation

/// A utility for accessing and loading local resources from a bundle.
///
/// The `Resource` type provides convenience methods to locate and load resources,
/// such as JSON files, audio, images, or any other bundled assets.
public enum Resource {

    /// Returns the URL of a resource within a given bundle.
    ///
    /// Use this method when you need to locate a file that is packaged with the app
    /// or framework bundle.
    ///
    /// ```swift
    /// let url = try Resource.url(name: "onboarding-scene", ext: "json")
    /// ```
    ///
    /// - Parameters:
    ///   - name: The name of the resource file **without** its extension.
    ///   - ext: The resource’s file extension (for example, `"json"`). Pass `nil` for files without an extension.
    ///   - bundle: The bundle to search. Defaults to `.main`.
    /// - Throws: ``ResourceError/resourceNotFound(name:ext:)`` if the resource could not be located.
    /// - Returns: A `URL` pointing to the requested resource.
    public static func url(name: String, ext: String? = nil, in bundle: Bundle = .main) throws -> URL {
        guard let url = bundle.url(forResource: name, withExtension: ext) else {
            throw ResourceError.resourceNotFound(name: name, ext: ext)
        }
        
        return url
    }
    
    /// Loads the raw data for a resource at the given URL.
    ///
    /// This is typically used in combination with ``url(name:ext:in:)`` to load
    /// data from a bundled file.
    ///
    /// ```swift
    /// let url = try Resource.url(name: "onboarding-scene", ext: "json")
    /// let data = try Resource.data(for: url)
    /// ```
    ///
    /// - Parameter url: The URL of the resource to load.
    /// - Throws: ``ResourceError/dataLoadingFailed(url:underlying:)`` if the data cannot be loaded.
    /// - Returns: A `Data` object containing the contents of the resource.
    public static func data(for url: URL) throws -> Data {
        do {
            return try Data(contentsOf: url)
        } catch {
            throw ResourceError.dataLoadingFailed(url: url, underlying: error)
        }
    }
}
