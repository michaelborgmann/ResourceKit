//
//  ResourcePackage.swift
//  ResourceKit
//
//  Created by Michael Borgmann on 09/02/2026.
//

/// A logical grouping of resources that can be resolved and loaded together.
///
/// A `ResourcePackage` describes where a collection of related resources
/// is located and how individual resources within that package can be
/// addressed by stable keys. Packages may reside in the app bundle, on the
/// local filesystem, or at a remote location.
///
/// The package itself contains no domain-specific knowledge; it only defines
/// how resources are identified and where their data can be found.
public struct ResourcePackage: Codable, Sendable {
    
    /// Schema version of the package description.
    public let schema: Int
    
    /// Stable identifier for the resource package.
    public let packageId: String
    
    /// Version string describing the contents of the package.
    public let version: String
    
    /// Path identifying where the resource package is located (bundle-relative, filesystem-absolute, or remote URL).
    /// Examples:
    /// ```
    /// "relative/path"
    /// "/absolute/path"
    /// "https://example.com/remote/path"
    /// ```
    public let path: String
    
    /// The list of resource entries contained in this package.
    public let resources: [ResourceEntity]
}

// MARK: - Resource Entity

public extension ResourcePackage {
    
    /// Describes a single resource contained within a resource package.
    ///
    /// A resource entity associates a stable key with a file path relative
    /// to the package location. The key is used by clients to refer to the
    /// resource without depending on its physical storage layout.
    public struct ResourceEntity: Codable, Sendable {
        
        /// Stable identifier for the resource.
        public let key: String
        
        /// Relative file path of the resource within the package.
        public let file: String
    }
}
