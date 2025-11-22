//
//  AudioResourcePlayer.swift
//  ResourceKit
//
//  Created by Michael Borgmann on 28/08/2025.
//

import AVFoundation

/// A lightweight, main-actor–isolated audio player built on top of `AVAudioPlayer`.
///
/// `AudioResourcePlayer` provides a clean, UI-friendly API for loading and controlling audio,
/// with built-in support for precise segment playback and looping.
///
/// ### Features
/// - Load and prepare local audio files from any bundle.
/// - Play, pause, resume, and stop playback.
/// - Control volume and whole-file looping via ``numberOfLoops``.
/// - Play clamped audio **segments** with optional finite or infinite looping.
/// - Drift-free segment scheduling using wall-clock–anchored timers.
///
/// ### Segment Playback
/// In addition to whole-file playback, `AudioResourcePlayer` supports playing **time slices**
/// of an audio file. Segments are scheduled relative to a stable wall-clock anchor to
/// avoid cumulative drift over many loops:
///
/// ```swift
/// try player.play(fromSeconds: 2.0, toSeconds: 4.0, loops: .times(3))
/// ```
///
/// This example plays the range `[2.0, 4.0)` and loops it **3 extra times** (4 total).
/// Segment looping uses internal timers rather than `AVAudioPlayer.numberOfLoops`,
/// giving precise control even for partial slices.
///
/// ### Concurrency & Thread Safety
/// - The entire API is **`@MainActor` isolated** — all state changes calls are
///   guaranteed to happen on the main actor.
/// - Safe for UI-driven use without manual thread management.
/// - Uses a selector-based `Timer` internally, ensuring Swift 6 `@Sendable` safety.
///
/// ### Error Handling
/// All fallible operations throw ``AudioResourcePlayerError``:
/// - ``AudioResourcePlayerError/notLoaded`` — no file was loaded before playback.
/// - ``AudioResourcePlayerError/invalidRange`` — start ≥ end or out-of-bounds segment.
/// - ``AudioResourcePlayerError/playFailed`` — playback could not start.
/// - ``AudioResourcePlayerError/decodeFailed`` — the audio file could not be decoded.
///
/// ### Example
/// ```swift
/// let player = AudioResourcePlayer()
/// try player.load(named: "beep", ext: "mp3", in: .module)
/// player.volume = 0.8
/// try player.play()
/// ```
///
/// ### Limitations
/// - Remote streaming is **not supported** — this is for locally bundled or downloaded files.
/// - For precise musical timing, use `AVAudioPlayer.deviceCurrentTime` and `play(atTime:)`.
///
/// `AudioResourcePlayer` is designed for apps that need **simple, predictable, and safe**
/// audio playback without the complexity of `AVAudioEngine`.
@MainActor
public final class AudioResourcePlayer: NSObject {
    
    // MARK: - Private Properties

    /// The underlying audio player instance.
    private var player: AVAudioPlayer?
    
    /// Timer used to stop (or re-trigger) playback when playing a segment.
    private var stopTimer: Timer?
    
    /// Start time of the active segment (in seconds).
    private var segmentStart: TimeInterval = 0
    
    /// Remaining loop count for the current segment (0 = once, -1 = infinite).
    private var remainingLoops: Int = 0
    
    /// Whether a segment is currently in looping mode.
    private var isSegmentLooping: Bool = false
    
    /// Anchor wall-clock time used to prevent drift when rescheduling loops.
    private var segmentAnchorWallTime: CFAbsoluteTime = 0
    
    /// Duration of the current segment (in seconds).
    private var segmentLength: TimeInterval = 0
    
    /// Remaining time in the current segment when paused (nil if not paused mid-loop).
    private var pausedRemaining: TimeInterval?
    
    /// Looping modes for segment playback. Controls how many times the segment is repeated.
    public enum Looping: Equatable {
        
        /// Play the segment once (no extra loops).
        case once
        
        /// Loop the segment a specific number of extra times (`.times(3)` plays 4 total).
        case times(Int)
        
        /// Loop the segment indefinitely.
        case infinite
    }
    
    // MARK: - Public Properties
    
    /// Callback invoked whenever the playback state changes.
    ///
    /// - Parameter isPlaying: `true` if playback started or resumed, `false` if paused or stopped.
    /// - Note: This is triggered for both whole-file and segment playback.
    ///         Segment playback may call this multiple times for loop restarts.
    public var onPlaybackStateChange: ((Bool) -> Void)?

    /// Callback invoked when playback finishes naturally.
    ///
    /// - Note:
    ///   - Triggered only when the audio finishes playing to the end (whole-file playback).
    ///   - **Not called for segment playback**; segment loops are managed by internal timers and do not fire this callback.
    ///   - Useful for auto-advancing to the next verse or updating UI when playback completes.
    public var onPlaybackFinished: (() -> Void)?
    
    /// Indicates whether the audio player is currently playing.
    public var isPlaying: Bool {
        player?.isPlaying ?? false
    }
    
    /// Controls the playback volume (`0.0` = mute, `1.0` = max).
    public var volume: Float {
        get { player?.volume ?? 1.0 }
        set { player?.volume = max(0.0, min(newValue, 1.0)) }
    }
    
    /// Whole-file loop count.
    ///
    /// - Note: This applies **only** to whole-file playback via `play()`.
    ///         Segment playback ignores this and uses `Looping` instead.
    ///
    /// Values:
    /// - `0`  → play once
    /// - `n`  → loop `n` extra times
    /// - `-1` → infinite
    public var numberOfLoops: Int = 0 {
        didSet { player?.numberOfLoops = numberOfLoops }
    }
    
    // MARK: - Initialization & Lifecycle

    /// Creates a new instance of `AudioResourcePlayer`.
    public override init() {}
    
    /// Cleans up resources on deallocation.
    ///
    /// Ensures that any active stop timer is invalidated when the instance is released.
    deinit {
        stopTimer?.invalidate()
    }
    
    // MARK: - Loading
    
    /// Loads an audio file into memory and prepares it for playback.
    ///
    /// Calling this stops any existing playback and clears internal state.
    ///
    /// - Parameters:
    ///   - name: The resource name of the audio file.
    ///   - ext: The file extension. Defaults to `"mp3"`.
    ///   - bundle: The bundle containing the resource. Defaults to `.main`.
    /// - Throws: An error if the file cannot be located or loaded.
    public func load(named name: String, ext: String = "mp3", in bundle: Bundle = .main) throws {
        
        // Stop & clear any existing player before replacing it.
        player?.stop()
        cancelTimer()
        isSegmentLooping = false
        pausedRemaining = nil
        
        let url = try Resource.url(name: name, ext: ext, in: bundle)
        let newPlayer: AVAudioPlayer
        do {
            newPlayer = try AVAudioPlayer(contentsOf: url)
        } catch {
            throw AudioResourcePlayerError.decodeFailed(underlying: error)
        }
        
        newPlayer.delegate = self
        newPlayer.prepareToPlay()
        newPlayer.numberOfLoops = numberOfLoops // honor current setting
        player = newPlayer
    }
    
    // MARK: - Whole-File Playback Controls

    /// Starts playback from the current position.
    ///
    /// - Important:
    ///   - If a timed segment was previously active *and paused mid-segment*, this resumes it
    ///     for the remaining duration.
    ///   - Otherwise it plays the whole file, honoring ``numberOfLoops``.
    ///   - **Triggers `onPlaybackStateChange` with `true` when playback starts.**
    ///
    /// - Throws:
    ///   - ``AudioResourcePlayerError/notLoaded`` if no file has been loaded.
    ///   - ``AudioResourcePlayerError/playFailed`` if playback could not be started.
    public func play() throws {
        guard let player else { throw AudioResourcePlayerError.notLoaded }

        if isSegmentLooping, let remaining = pausedRemaining {
            // Store how much time is left in the current cycle
            pausedRemaining = nil
            guard player.play() else { throw AudioResourcePlayerError.playFailed }
            segmentAnchorWallTime = CFAbsoluteTimeGetCurrent()  // reset anchor for resume
            startSegmentTimer(fireAfter: remaining)
        } else {
            player.numberOfLoops = numberOfLoops
            cancelTimer()
            isSegmentLooping = false
            guard player.play() else { throw AudioResourcePlayerError.playFailed }
        }
        
        onPlaybackStateChange?(true)
    }
    
    /// Pauses playback, keeping the current position.
    ///
    /// - Important:
    ///   - **Triggers `onPlaybackStateChange` with `false` when playback pauses.**
    ///
    /// - Note: If a segment is looping, the remaining time for the current cycle
    ///         is captured so that `play()` can resume the segment accurately.
    public func pause() {
        guard let player else { return }
        
        if isSegmentLooping {
            // store how much time was left in the current cycle
            let elapsed = player.currentTime - segmentStart
            let remaining = max(0, segmentLength - elapsed)
            pausedRemaining = remaining
        }
        
        player.pause()
        cancelTimer()
        onPlaybackStateChange?(false)
    }
    
    /// Stops playback and resets state.
    ///
    /// Cancels any active segment timer and clears segment state.
    ///
    /// - Important:
    ///   - **Triggers `onPlaybackStateChange` with `false` when playback stops.**
    public func stop() {
        player?.stop()
        cancelTimer()
        isSegmentLooping = false
        pausedRemaining = nil
        onPlaybackStateChange?(false)
    }
    
    // MARK: - Segment Playback

    /// Plays a specific segment of the loaded audio file.
    ///
    /// The player clamps `start` and `end` to valid bounds and ensures the range is positive.
    /// Any existing timers are canceled before playback starts.
    ///
    /// - Parameters:
    ///   - start: The segment start time in seconds.
    ///   - end: The segment end time in seconds (non-inclusive).
    ///   - loops: Looping mode. Use `.once` (default), `.times(n)`, or `.infinite`.
    ///
    /// - Important: Segment looping is implemented by re-triggering the segment
    ///              with a timer. Whole-file looping is **not** used for segments.
    /// - Note: `.times(0)` behaves like `.once`.
    public func play(fromSeconds start: TimeInterval, toSeconds end: TimeInterval, loops: Looping = .once) throws {
        
        guard let player = player else { throw AudioResourcePlayerError.notLoaded }

        // Clamp & validate

        let startClamped = max(0, min(start, player.duration))
        let endClamped = max(startClamped, min(end, player.duration))
        let length = endClamped - startClamped
        guard length > 0 else {
            throw AudioResourcePlayerError.invalidRange(start: start, end: end, duration: player.duration)
        }
        
        // Reset segment state
        cancelTimer()
        isSegmentLooping = (loops != .once)
                
        switch loops {
        case .once:
            remainingLoops = 0
        case .times(let n):
            remainingLoops = max(0, n) // 0 extra repeats == once
        case .infinite:
            remainingLoops = -1
        }
        
        segmentStart = startClamped
        segmentLength = length
        pausedRemaining = nil
        
        // Configure and start
        player.stop()
        player.currentTime = startClamped
        player.numberOfLoops = 0            // AVAudioPlayer loops the whole file; we loop the segment.
        player.prepareToPlay()
        let ok = player.play()
        if !ok { throw AudioResourcePlayerError.playFailed }
        
        // Anchor “now” so reschedules don’t accumulate drift
        segmentAnchorWallTime = CFAbsoluteTimeGetCurrent()
        startSegmentTimer(fireAfter: length)
    }
    
    // MARK: - Timer Management

    /// Starts (or re-starts) the segment timer.
    ///
    /// This method sets up a one-shot `Timer` to control when a segment should end
    /// or restart if looping is enabled.
    ///
    /// Unlike a repeating timer, this schedules **one fire at a precise wall-clock time**
    /// relative to `segmentAnchorWallTime` to prevent cumulative drift over many loops.
    ///
    /// The timer fires `segmentTimerDidFire(_:)` on the **main run loop**.
    ///
    /// > Note:
    /// Using a selector-based `Timer` avoids Swift 6's `@Sendable` closure restrictions
    /// when accessing `@MainActor` properties like `player`.
    ///
    /// - Parameter fireAfter: The number of seconds from **now** until the timer fires.
    private func startSegmentTimer(fireAfter: TimeInterval) {
        
        // Replace the previous timer safely
        stopTimer?.invalidate()

        // Schedule relative to the original anchor to avoid cumulative slippage on many loops.
        let intendedFire = segmentAnchorWallTime + fireAfter
        let delay = max(0, intendedFire - CFAbsoluteTimeGetCurrent())

        let timer = Timer(
            timeInterval: delay, target: self,
            selector: #selector(segmentTimerDidFire(_:)),
            userInfo: nil, repeats: false
        )
        
        timer.tolerance = min(0.02, fireAfter * 0.1)
        RunLoop.main.add(timer, forMode: .common)
        stopTimer = timer
    }

    /// Called when the active segment timer fires.
    ///
    /// - If segment looping is enabled and more loops remain (or infinite looping is set),
    ///   the method restarts the audio segment from `segmentStart`, prepares the player,
    ///   and reschedules the next timer.
    /// - Otherwise, it stops playback and clears looping state.
    /// - Calls `onPlaybackStateChange` whenever the playback state changes
    ///   (true when segment restarts, false when segment ends).
    ///
    /// > Important:
    /// This method is always invoked on the **main run loop**, matching `@MainActor` isolation.
    ///
    /// - Parameter timer: The timer that fired.
    @objc private func segmentTimerDidFire(_ timer: Timer) {
        guard let player = self.player else { return }

        if self.isSegmentLooping, (self.remainingLoops > 0 || self.remainingLoops == -1) {
            if self.remainingLoops > 0 { self.remainingLoops -= 1 }

            // Restart the slice
            player.stop()
            player.currentTime = self.segmentStart
            player.prepareToPlay()
            _ = player.play()       // best-effort; segment re-triggers are internal
            
            // Advance anchor one full length; schedule next on anchor (prevents drift)
            self.segmentAnchorWallTime += self.segmentLength
            self.startSegmentTimer(fireAfter: self.segmentLength)
            
            // Only notify if playback state actually changed
            if !player.isPlaying {
                onPlaybackStateChange?(true)
            }
            
        } else {
            player.stop()
            self.isSegmentLooping = false
            self.stopTimer = nil
            
            onPlaybackStateChange?(false)
        }
    }
    
    /// Cancels any active segment timer.
    private func cancelTimer() {
        stopTimer?.invalidate()
        stopTimer = nil
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioResourcePlayer: AVAudioPlayerDelegate {
    
    /// Called by the system when `AVAudioPlayer` finishes playing a file.
    ///
    /// - Parameters:
    ///   - player: The `AVAudioPlayer` instance that finished playback.
    ///   - flag: `true` if playback reached the end successfully, `false` if interrupted or failed.
    /// - Note: This method triggers both `onPlaybackStateChange(false)` and `onPlaybackFinished?()`,
    ///         allowing UI and consumers to respond to playback completion.
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onPlaybackStateChange?(false)
        onPlaybackFinished?()
    }
}
