//
//  AudioResourcePlayerTests.swift
//  ResourceKit
//
//  Created by Michael Borgmann on 29/08/2025.
//

import Testing
@testable import ResourceKit
import AVFoundation

// MARK: - Helpers

@MainActor
private func ensureAudioSessionActive() {
    #if os(iOS) || os(tvOS)
    let s = AVAudioSession.sharedInstance()
    try? s.setCategory(.ambient, options: [.mixWithOthers])
    try? s.setActive(true)
    #endif
}

/// Runs the runloop for (roughly) `seconds`, allowing timers to fire.
@MainActor
private func spinRunloop(_ seconds: TimeInterval) {
    RunLoop.current.run(until: Date().addingTimeInterval(seconds))
}

@MainActor
private func waitUntil(_ condition: @autoclosure () -> Bool,
                       timeout: TimeInterval,
                       step: TimeInterval = 0.01) -> Bool {
    let deadline = Date().addingTimeInterval(timeout)
    while Date() < deadline {
        if condition() { return true }
        RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(step))
    }
    return condition()
}

/// Loads a tiny test asset like "beep.mp3".
@MainActor
private func makeLoadedPlayer(
    name: String = "beep",
    ext: String = "mp3",
    bundle: Bundle = .module
) throws -> AudioResourcePlayer {
    let p = AudioResourcePlayer()
    try p.load(named: name, ext: ext, in: bundle)
    return p
}

/// Returns the actual duration of the bundled asset.
@MainActor
private func assetDuration(name: String = "beep", ext: String = "mp3") throws -> TimeInterval {
    let url = try Resource.url(name: name, ext: ext, in: .module)
    let ref = try AVAudioPlayer(contentsOf: url)
    ref.prepareToPlay()
    return ref.duration
}

@MainActor
struct AudioResourcePlayerTests {

    // MARK: - Errors

    @Test
    func play_withoutLoad_throwsNotLoaded() {
        let p = AudioResourcePlayer()
        do {
            try p.play()
            Issue.record("Expected AudioResourcePlayerError.notLoaded, but no error was thrown.")
        } catch let error as AudioResourcePlayerError {
            switch error {
            case .notLoaded: break // ✅ correct
            default:
                Issue.record("Unexpected error case: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test
    func segment_invalidRange_throws() throws {
        let p = try makeLoadedPlayer()
        do {
            try p.play(fromSeconds: 0.4, toSeconds: 0.1)
            Issue.record("Expected AudioResourcePlayerError.invalidRange, but no error was thrown.")
        } catch let error as AudioResourcePlayerError {
            switch error {
            case .invalidRange: break // ✅ correct
            default:
                Issue.record("Wrong error case: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - Whole-file playback (smoke)

    @Test
    func load_and_play_wholeFile_startsPlayback() throws {
        ensureAudioSessionActive()

        let p = try makeLoadedPlayer()
        try p.play()
        #expect(p.isPlaying)
        p.stop()
        #expect(!p.isPlaying)
    }

    /// We only smoke-test that setting `numberOfLoops` does not break playback.
    /// Verifying *completion* timing with MP3 is flaky due to encoder padding.
    @Test
    func wholeFile_play_starts_when_numberOfLoops_set() throws {
        ensureAudioSessionActive()

        let p = try makeLoadedPlayer()
        p.numberOfLoops = 1
        try p.play()
        spinRunloop(0.05)
        #expect(p.isPlaying)
    }

    // MARK: - Segment playback (deterministic)
    
    @Test @MainActor
    func segment_once_stopsAfterLength() throws {
        let p = try makeLoadedPlayer(name: "beep", ext: "mp3", bundle: .module)
        try p.play(fromSeconds: 0.0, toSeconds: 0.3, loops: .once)
        spinRunloop(0.05); #expect(p.isPlaying)
        spinRunloop(0.40); #expect(!p.isPlaying)   // includes buffer for scheduling
    }
    
    @Test @MainActor
    func segment_timesN_loopsExactCount() throws {
        let p = try makeLoadedPlayer(name: "beep", ext: "mp3", bundle: .module)
        try p.play(fromSeconds: 0.0, toSeconds: 0.25, loops: .times(2))
        spinRunloop(0.10); #expect(p.isPlaying)    // first pass
        spinRunloop(0.30); #expect(p.isPlaying)    // second pass
        spinRunloop(0.45); #expect(!p.isPlaying)   // all done
    }

    @Test @MainActor
    func pause_resume_segment_honorsRemaining() throws {
        let p = try makeLoadedPlayer(name: "beep", ext: "mp3", bundle: .module)
        try p.play(fromSeconds: 0.0, toSeconds: 0.5, loops: .times(1))
        spinRunloop(0.2)
        p.pause(); #expect(!p.isPlaying)
        try p.play()
        spinRunloop(0.3); #expect(p.isPlaying)     // finishing remaining + will loop once
        spinRunloop(0.6); #expect(!p.isPlaying)
    }

    @Test
    func stop_cancelsTimers_andStops() throws {
        ensureAudioSessionActive()

        let d = try assetDuration()
        let segLen = max(0.30, min(0.60, d * 0.8))

        let p = try makeLoadedPlayer()
        try p.play(fromSeconds: 0.0, toSeconds: segLen, loops: .infinite)

        spinRunloop(min(0.05, segLen * 0.2))
        #expect(p.isPlaying)

        p.stop()
        #expect(!p.isPlaying)

        // Give timer a chance to (not) re-fire.
        spinRunloop(min(0.15, segLen * 0.5))
        #expect(!p.isPlaying)
    }

    // MARK: - Properties

    @Test
    func volume_isClamped() throws {
        let p = try makeLoadedPlayer()
        p.volume = -1
        #expect(p.volume == 0)
        p.volume = 2
        #expect(p.volume == 1)
    }
    
    // MARK: - Player Callback
    
    @Test @MainActor
    func onPlaybackStateChange_called_correctly() throws {
        let p = try makeLoadedPlayer()
        var states: [Bool] = []
        p.onPlaybackStateChange = { states.append($0) }
        
        try p.play()
        spinRunloop(0.05)
        #expect(states.last == true)
        
        p.pause()
        #expect(states.last == false)
        
        try p.play()
        spinRunloop(0.05)
        #expect(states.last == true)
        
        p.stop()
        #expect(states.last == false)
    }
}
