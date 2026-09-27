import DSAtoms
import DSMolecules
import DSTokens
import SwiftUI

/// Live view of the capture pipeline: elapsed time, input level, and which stage the
/// note is in. One place to look while a note is being created.
public struct DSRecordingPanel: View {
    public enum Stage: Sendable, Equatable {
        case recording
        case transcribing(progress: Double?)
        case enriching(progress: Double?)
        case saving
        case done
        case failed(String)

        var title: String {
            switch self {
            case .recording: "Grabando"
            case .transcribing: "Transcribiendo"
            case .enriching: "Mejorando con IA"
            case .saving: "Guardando"
            case .done: "Listo"
            case .failed: "No se pudo guardar"
            }
        }

        var systemImage: String {
            switch self {
            case .recording: "waveform"
            case .transcribing: "text.bubble"
            case .enriching: "sparkles"
            case .saving: "square.and.arrow.down"
            case .done: "checkmark.circle.fill"
            case .failed: "exclamationmark.triangle.fill"
            }
        }

        var isFailure: Bool {
            if case .failed = self { true } else { false }
        }

        var progress: Double? {
            switch self {
            case .transcribing(let p), .enriching(let p): p
            default: nil
            }
        }
    }

    private let stage: Stage
    private let elapsed: TimeInterval
    private let levels: [Double]
    private let onRetry: (() -> Void)?

    public init(
        stage: Stage,
        elapsed: TimeInterval = 0,
        levels: [Double] = [],
        onRetry: (() -> Void)? = nil
    ) {
        self.stage = stage
        self.elapsed = elapsed
        self.levels = levels
        self.onRetry = onRetry
    }

    public var body: some View {
        DSCard {
            VStack(alignment: .leading, spacing: Spacing.m) {
                HStack(spacing: Spacing.s) {
                    Image(systemName: stage.systemImage)
                        .foregroundStyle(stage.isFailure ? Palette.danger : Palette.accent)
                    Text(stage.title)
                        .font(Typography.headline)
                        .foregroundStyle(Palette.textPrimary)
                    Spacer()
                    Text(DSNoteCard.formattedDuration(elapsed))
                        .font(Typography.timer)
                        .foregroundStyle(Palette.textTertiary)
                }

                switch stage {
                case .recording:
                    DSAudioLevelMeter(levels: levels, isActive: true)
                case .transcribing, .enriching:
                    DSProgressBar(progress: stage.progress)
                case .failed(let message):
                    Text(message)
                        .font(Typography.subheadline)
                        .foregroundStyle(Palette.danger)
                case .saving, .done:
                    DSProgressBar(progress: stage.isFailure ? nil : 1)
                }

                // Only rendered when the caller supplies the action: a retry button
                // wired to nothing is worse than no retry button.
                if case .failed = stage, let onRetry {
                    DSButton("Reintentar", kind: .secondary, action: onRetry)
                }
            }
        }
    }
}
