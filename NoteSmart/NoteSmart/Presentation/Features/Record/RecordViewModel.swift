//
//  RecordViewModel.swift
//  NoteSmart
//

import DSMolecules
import DSOrganisms
import Foundation
import NoteSmartDomain
import Observation

/// Drives capture: microphone → transcript → enrichment → markdown on disk.
///
/// The whole pipeline lives in `CreateNoteFromRecording`, so this type only owns the
/// parts a view needs and the domain does not: permission, the live meter, the stage
/// to draw, and what to do when a stage throws. Nothing here writes a note.
@MainActor
@Observable
final class RecordViewModel {

    enum State: Equatable {
        case idle
        case recording
        case processing
        case failed(String)
    }

    /// How many bars the waveform keeps. Wide enough to read as a waveform, short
    /// enough that the animation stays cheap at 60fps.
    private static let meterWindow = 28

    private(set) var state: State = .idle
    private(set) var elapsed: TimeInterval = 0
    private(set) var levels: [Double] = []
    private(set) var liveTranscript: String = ""

    /// Called once the note is on disk, so the list can open it.
    var onNoteSaved: ((Note) -> Void)?

    private let environment: AppEnvironment
    private var pipelineStage: DSRecordingPanel.Stage = .saving
    private var meterTask: Task<Void, Never>?
    private var pipelineTask: Task<Void, Never>?

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    // MARK: - Derived view state

    var buttonState: DSRecordingButton.State {
        switch state {
        case .idle: .idle
        case .recording: .recording(elapsed: elapsed)
        case .processing, .failed: .processing
        }
    }

    /// `nil` when there is nothing to report beyond the button itself.
    var panel: DSRecordingPanel.Stage? {
        switch state {
        case .idle: nil
        case .recording: .recording
        case .processing: pipelineStage
        case .failed(let message): .failed(message)
        }
    }

    var isBusy: Bool {
        state == .processing
    }

    // MARK: - Commands

    /// One control for the whole capture: start when idle, stop when recording.
    func toggle() async {
        switch state {
        case .idle: await start()
        case .recording: await stop()
        case .processing, .failed: break
        }
    }

    /// Clears a failure and returns to the idle button.
    func dismissFailure() async {
        await environment.recorder.cancel()
        state = .idle
    }

    // MARK: - Capture

    private func start() async {
        let granted = await requestMicrophone()
        guard granted else {
            state = .failed(AppErrorMessage.text(for: TranscriptionError.permissionDenied))
            return
        }

        do {
            try await environment.recorder.start(destination: environment.newRecordingDestination())
            elapsed = 0
            levels = []
            liveTranscript = ""
            state = .recording
            startMetering()
        } catch {
            state = .failed(AppErrorMessage.text(for: error))
        }
    }

    private func requestMicrophone() async -> Bool {
        switch await environment.recorder.authorizationStatus() {
        case .authorized:
            true
        case .denied:
            false
        case .notDetermined:
            await environment.recorder.requestAuthorization()
        }
    }

    private func startMetering() {
        meterTask?.cancel()
        // The environment and window are captured up front and `self` is only held for
        // the body of each iteration. Hoisting `guard let self` above the `for await`
        // retained the model for the life of the stream, so the task and the model
        // kept each other alive forever.
        let environment = self.environment
        let window = Self.meterWindow
        meterTask = Task { [weak self] in
            for await reading in await environment.recorder.meter() {
                guard let self, !Task.isCancelled else { return }
                self.elapsed = reading.elapsed
                self.levels.append(Double(reading.level))
                if self.levels.count > window {
                    self.levels.removeFirst(self.levels.count - window)
                }
            }
        }
    }

    // MARK: - Pipeline

    private func stop() async {
        meterTask?.cancel()
        meterTask = nil
        state = .processing
        pipelineStage = .saving

        let audio: AudioFileRef
        do {
            let recording = try await environment.recorder.stop()
            audio = environment.audioFile(for: recording)
        } catch {
            state = .failed(AppErrorMessage.text(for: error))
            return
        }

        runPipeline(audio)
    }

    private func runPipeline(_ audio: AudioFileRef) {
        pipelineTask?.cancel()
        let environment = self.environment
        pipelineTask = Task { [weak self] in
            do {
                for try await stage in await environment.createNoteFromRecording(audio) {
                    guard let self, !Task.isCancelled else { return }
                    switch stage {
                    case .installingModel(let progress):
                        // Speech gives a real fraction while the model downloads and
                        // nothing at all while it transcribes, so the same bar covers
                        // both and simply changes between determinate and not.
                        pipelineStage = .transcribing(progress: progress.fractionCompleted)

                    case .transcribing(let progress):
                        pipelineStage = .transcribing(progress: nil)
                        liveTranscript = progress.displayText

                    case .enriching:
                        pipelineStage = .enriching(progress: nil)

                    case .saved(let note):
                        pipelineStage = .done
                        let onNoteSaved = self.onNoteSaved
                        self.reset()
                        onNoteSaved?(note)
                        return
                    }
                }
                // The stream finished without a `.saved` stage: the use case
                // completed but produced no note, which should not happen.
                guard let self, !Task.isCancelled else { return }
                state = .failed(AppErrorMessage.text(for: TranscriptionError.emptyRecording))
            } catch is CancellationError {
                guard let self, !Task.isCancelled else { return }
                state = .idle
            } catch {
                guard let self, !Task.isCancelled else { return }
                state = .failed(AppErrorMessage.text(for: error))
            }
        }
    }

    private func reset() {
        state = .idle
        elapsed = 0
        levels = []
        liveTranscript = ""
        pipelineStage = .saving
    }
}
