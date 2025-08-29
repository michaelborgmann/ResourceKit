//
//  AudioResourcePlayerError.swift
//  ResourceKit
//
//  Created by Michael Borgmann on 29/08/2025.
//

import Foundation

public enum AudioResourcePlayerError: LocalizedError {
    
    /// No audio file is currently loaded.
    case notLoaded
    
    /// The requested playback range is invalid (start ≥ end or outside duration).
    case invalidRange(start: TimeInterval, end: TimeInterval, duration: TimeInterval)
    
    /// Playback could not be started (AVAudioPlayer returned false).
    case playFailed
    
    /// The underlying AVAudioPlayer decode failed.
    case decodeFailed(underlying: Error?)
    
    // MARK: - LocalizedError
    
    public var errorDescription: String? {
        switch self {
        case .notLoaded:
            return NSLocalizedString("No audio file has been loaded.", comment: "")
        case .invalidRange:
            return NSLocalizedString("The requested playback range is invalid.", comment: "")
        case .playFailed:
            return NSLocalizedString("Audio playback could not be started.", comment: "")
        case .decodeFailed:
            return NSLocalizedString("The audio file could not be decoded.", comment: "")
        }
    }
    
    public var failureReason: String? {
        switch self {
        case .notLoaded:
            return NSLocalizedString("`load(named:ext:in:)` has not been called before attempting playback.", comment: "")
        case .invalidRange(let start, let end, let duration):
            return NSLocalizedString("Requested range [\(start)–\(end)) is outside the file duration (\(duration)).", comment: "")
        case .playFailed:
            return NSLocalizedString("`AVAudioPlayer.play()` returned false.", comment: "")
        case .decodeFailed(let underlying):
            if let u = underlying {
                return NSLocalizedString("AVAudioPlayer reported a decoding error: \(u.localizedDescription)", comment: "")
            } else {
                return NSLocalizedString("AVAudioPlayer reported a decoding error without details.", comment: "")
            }
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .notLoaded:
            return NSLocalizedString("Call `load(...)` with a valid audio resource before playing.", comment: "")
        case .invalidRange:
            return NSLocalizedString("Adjust the start and end times to a valid range within the file duration.", comment: "")
        case .playFailed:
            return NSLocalizedString("Verify the audio session is active and the file is playable.", comment: "")
        case .decodeFailed:
            return NSLocalizedString("Ensure the audio file is not corrupted and is a supported format.", comment: "")
        }
    }
}
