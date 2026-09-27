import DSTokens
import SwiftUI

/// Live input level while recording. Gives the user proof the microphone is
/// actually hearing them, which is the most common support question in voice apps.
public struct DSAudioLevelMeter: View {
    private let levels: [Double]
    private let isActive: Bool

    public init(levels: [Double], isActive: Bool) {
        self.levels = levels
        self.isActive = isActive
    }

    public var body: some View {
        HStack(alignment: .center, spacing: Spacing.xxs) {
            ForEach(Array(levels.enumerated()), id: \.offset) { _, level in
                Capsule()
                    .fill(Palette.recording.opacity(isActive ? 0.35 + level * 0.65 : 0.2))
                    .frame(width: 3, height: 4 + level * 20)
            }
        }
        .frame(height: 28, alignment: .center)
        .animation(Motion.Spring.gentle, value: levels)
        .accessibilityHidden(true)
    }
}

/// Determinate and indeterminate progress for the transcription/AI pipeline.
public struct DSProgressBar: View {
    private let progress: Double?
    private let tint: AdaptiveColor

    public init(progress: Double?, tint: AdaptiveColor = Palette.accent) {
        self.progress = progress
        self.tint = tint
    }

    public var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Palette.surfaceSunken)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, progress ?? 0)) * proxy.size.width)
            }
        }
        .frame(height: 4)
        .animation(.easeInOut(duration: Motion.Duration.fast), value: progress)
        .accessibilityHidden(true)
    }
}
