import DSTokens
import SwiftUI

/// The capture control. Three states, and the only element allowed to use the
/// recording color at full strength.
public struct DSRecordingButton: View {
    public enum State: Sendable {
        case idle
        case recording(elapsed: TimeInterval)
        case processing
    }

    private let state: State
    private let isEnabled: Bool
    private let onTap: () -> Void

    public init(state: State, isEnabled: Bool = true, onTap: @escaping () -> Void) {
        self.state = state
        self.isEnabled = isEnabled
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            ZStack {
                outerRing
                innerDisc
            }
            .frame(width: Metrics.recordButton, height: Metrics.recordButton)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.4)
        .animation(Motion.Spring.bouncy, value: state.isRecording)
        .accessibilityLabel(Text(state.accessibilityLabel))
        .accessibilityHint(Text(state.accessibilityHint))
        .accessibilityAddTraits(.isButton)
    }

    private var outerRing: some View {
        Circle()
            .fill(Palette.recording.opacity(0.12))
            .scaleEffect(state.isRecording ? 1.0 : 0.82)
    }

    private var innerDisc: some View {
        ZStack {
            Circle()
                .fill(state.fillColor)

            if case .recording = state {
                // Morphs the disc into the familiar stop square.
                RoundedRectangle(cornerRadius: Radius.s, style: .continuous)
                    .fill(Palette.textOnAccent)
                    .frame(width: 24, height: 24)
            } else if case .processing = state {
                ProgressView()
                    .tint(Palette.textOnAccent)
            } else {
                Circle()
                    .fill(Palette.textOnAccent)
                    .frame(width: 52, height: 52)
            }
        }
        .frame(width: 60, height: 60)
    }
}

private extension DSRecordingButton.State {
    var isRecording: Bool {
        if case .recording = self { true } else { false }
    }

    var fillColor: AdaptiveColor {
        switch self {
        case .idle: Palette.recording
        case .recording: Palette.recording
        case .processing: Palette.textTertiary
        }
    }

    var accessibilityLabel: String {
        switch self {
        case .idle: "Iniciar grabación"
        case .recording(let elapsed): "Detener grabación, \(Int(elapsed)) segundos"
        case .processing: "Procesando"
        }
    }

    var accessibilityHint: String {
        switch self {
        case .idle: "Toca para grabar una nota de voz"
        case .recording: "Toca para detener y guardar"
        case .processing: "Transcribiendo la nota"
        }
    }
}
