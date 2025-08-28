//
//  ResourceError.swift
//  ResourceKit
//
//  Created by Michael Borgmann on 28/08/2025.
//

import Foundation

public enum ResourceError: LocalizedError {
    
    case resourceNotFound(name: String, ext: String?)
    case dataLoadingFailed(url: URL, underlying: Error)
    case jsonDecodingFailed(underlying: Error)

    // MARK: - LocalizedError
    
    public var errorDescription: String? {
        switch self {
        case .resourceNotFound:
            return NSLocalizedString("The requested resource could not be found.", comment: "")
        case .dataLoadingFailed:
            return NSLocalizedString("Unable to load resource data.", comment: "")
        case .jsonDecodingFailed:
            return NSLocalizedString("Failed to decode JSON data.", comment: "")
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .resourceNotFound(let name, let ext):
            return NSLocalizedString("Resource '\(name)\(ext.map { ".\($0)" } ?? "")' does not exist in the bundle.", comment: "")
        case .dataLoadingFailed(let url, let underlying):
            return NSLocalizedString("Could not read data from \(url.absoluteString). Underlying error: \(underlying.localizedDescription)", comment: "")
        case .jsonDecodingFailed(let underlying):
            return NSLocalizedString("The JSON data could not be parsed. Underlying error: \(underlying.localizedDescription)", comment: "")
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .resourceNotFound:
            return NSLocalizedString("Verify the resource name, file extension, and bundle settings.", comment: "")
        case .dataLoadingFailed:
            return NSLocalizedString("Ensure the file exists and is accessible.", comment: "")
        case .jsonDecodingFailed:
            return NSLocalizedString("Check that the JSON matches the expected model and types.", comment: "")
        }
    }
}
