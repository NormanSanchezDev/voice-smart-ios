import Foundation
import NoteSmartDomain
import Testing

@testable import NoteSmartData

/// Regression tests for the capture state machine.
///
/// Every test here runs without a microphone. The bug these lock down was a guard that
/// returned out of `start()` before doing any work, which then made `stop()` detach a
/// tap that was never installed and report an empty recording — so the user pressed
/// the button, watched it "record", and lost the audio with no error until
/// transcription failed much later.
@Suite("Audio engine recorder")
struct AudioEngineRecorderTests {

    /// Tearing down a recorder that never captured must not touch the input node.
    @Test("Stopping a recorder that never started reports an empty recording")
    func stopWithoutStart() async {
        let recorder = AudioEngineRecorder()

        await expectEmptyRecording { return try await recorder.stop() }
    }

    @Test("Cancelling a recorder that never started is a no-op")
    func cancelWithoutStart() async {
        let recorder = AudioEngineRecorder()

        // Never throws, and must not raise: the old teardown removed a tap that was
        // not there.
        await recorder.cancel()
    }

    @Test("Stopping twice still reports an empty recording instead of raising")
    func stopIsIdempotent() async {
        let recorder = AudioEngineRecorder()

        await expectEmptyRecording { return try await recorder.stop() }
        await expectEmptyRecording { return try await recorder.stop() }
    }

    @Test("Authorization starts as a question the app has not asked yet")
    func authorizationIsUndeterminedFirst() async {
        let recorder = AudioEngineRecorder()

        let status = await recorder.authorizationStatus()
        #expect(status == .notDetermined || status == .denied)
    }

    // Not covered here, and it should not pretend otherwise: that each capture gets a
    // fresh meter stream, and that the written file has frames, both need a real input
    // node. The simulator reports a zero-rate input, so a test written here would be a
    // test that cannot fail. Verify those on a device.

    // MARK: - Helper

    private func expectEmptyRecording(
        _ operation: () async throws -> AudioRecording,
        sourceLocation: SourceLocation = #_sourceLocation
    ) async {
        do {
            _ = try await operation()
            Issue.record("expected TranscriptionError.emptyRecording", sourceLocation: sourceLocation)
        } catch {
            #expect(
                error as? TranscriptionError == .emptyRecording,
                sourceLocation: sourceLocation
            )
        }
    }
}
