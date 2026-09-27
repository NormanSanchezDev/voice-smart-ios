//
//  AudioPlaybackController.swift
//  NoteSmart
//

import AVFoundation
import Foundation
import Observation

/// Playback of a note's audio, exposing the clock the transcript follows.
///
/// The clock is polled rather than observed: `AVPlayer` would need a KVO or a
/// periodic-time observer, and both have to be torn down somewhere. A cancellable
/// `Task` stops on its own when playback stops or the screen goes away, so there is
/// no observer to leak.
@MainActor
@Observable
final class AudioPlaybackController {

    private(set) var isPlaying = false
    private(set) var currentTime: TimeInterval = 0
    private(set) var duration: TimeInterval = 0
    private(set) var isUnavailable = false

    private var player: AVPlayer?
    private var ticker: Task<Void, Never>?

    var progress: Double {
        guard duration > 0 else { return 0 }
        return min(1, max(0, currentTime / duration))
    }

    var isLoaded: Bool { player != nil }

    /// Points the player at a recording. `fallbackDuration` is used until the file
    /// reports its own, and kept if the file never does, so the scrubber always has a
    /// range.
    func load(url: URL, fallbackDuration: TimeInterval) {
        unload()
        duration = max(0, fallbackDuration)

        guard FileManager.default.fileExists(atPath: url.path) else {
            isUnavailable = true
            return
        }

        let player = AVPlayer(url: url)
        self.player = player
        isUnavailable = false

        Task { [weak self] in
            guard let self, let asset = player.currentItem?.asset else { return }
            guard let reported = try? await asset.load(.duration) else { return }

            let seconds = CMTimeGetSeconds(reported)
            // A reported duration of zero means the asset is not ready yet, not
            // that the recording is empty.
            if seconds.isFinite, seconds > 0 { duration = seconds }
        }
    }

    func toggle() {
        guard let player else { return }
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        guard let player, !isPlaying else { return }
        // Replaying from the end after a finish would silently do nothing.
        if duration > 0, currentTime >= duration - 0.05 {
            player.seek(to: .zero)
        }
        player.play()
        isPlaying = true
        startTicking()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        ticker?.cancel()
        ticker = nil
    }

    func seek(to time: TimeInterval) {
        guard let player else { return }
        let clamped = min(max(0, time), duration)
        player.seek(to: CMTime(seconds: clamped, preferredTimescale: 600))
        currentTime = clamped
    }

    func seek(toFraction fraction: Double) {
        seek(to: duration * min(1, max(0, fraction)))
    }

    func unload() {
        ticker?.cancel()
        ticker = nil
        player?.pause()
        player = nil
        isPlaying = false
        currentTime = 0
    }

    private func startTicking() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(100))
                guard let self, let player = self.player, self.isPlaying else { return }

                let seconds = player.currentTime().seconds
                guard seconds.isFinite else { continue }
                self.currentTime = seconds

                if self.duration > 0, seconds >= self.duration - 0.05 {
                    self.pause()
                    return
                }
            }
        }
    }
}
