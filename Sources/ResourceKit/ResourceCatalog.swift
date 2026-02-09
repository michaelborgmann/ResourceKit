//
//  ResourceCatalog.swift
//  ResourceKit
//
//  Created by Michael Borgmann on 09/02/2026.
//

/// A catalog of resource packages.
///
/// A `ResourceCatalog` is the entry point for discovering packages available to an app.
/// It lists packages by stable identifier and the path to each package definition.
/// The catalog contains no domain-specific information; it only describes where packages
/// can be found.
public struct ResourceCatalog: Codable, Sendable {
    
    /// Schema version of the catalog description.
    public let schema: Int
    
    /// Stable identifier for the resource catalog.
    public let catalogId: String
    
    /// Version string describing the contents of the catalog.
    public let version: String
    
    /// The package entries contained in this catalog.
    public let packages: [Package]
}

// MARK: Catalog Package

public extension ResourceCatalog {
    
    /// Describes a single package entry in a resource catalog.
    ///
    /// The `id` is a stable identifier for the package. The `path` specifies where the
    /// package is located (bundle-relative, filesystem-absolute, or remote URL), using
    /// the same semantics as `ResourcePackage.path`.
    struct Package: Codable, Sendable {
        
        /// Stable identifier for the package.
        public let id: String
        
        /// Path identifying where the package is located (bundle-relative, filesystem-absolute, or remote URL).
        public let path: String
    }
}
