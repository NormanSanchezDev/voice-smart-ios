import AVFAudio
import Foundation
import NoteSmartDomain

/// Realtime state for a capture in progress: the open file, whether the user paused,
/// and the level sink.
///
/// Deliberately a plain lock-guarded class rather than actor state. The tap closure
/// runs on the realtime audio thread, where hopping to an actor is not allowed, so
/// the hot path owns its own synchronisation.
private final class CaptureSession: @unchecked Sendable {
    private let lock = NSLock()
    private var file: AVAudioFile?
    private var writeError: Error?
    private var paused = false
    private var startedAt = Date.now
    private var accumulated: TimeInterval = 0
    private var pausedAt: Date?
    private var continuation: AsyncStream<AudioMeterReading>.Continuation?

    func begin(file: AVAudioFile, continuation: AsyncStream<AudioMeterReading>.Continuation?) {
        lock.lock()
        defer { lock.unlock() }
        self.file = file
        self.writeError = nil
        self.paused = false
        self.startedAt = .now
        self.accumulated = 0
        self.pausedAt = nil
        self.continuation = continuation
    }

    var isCapturing: Bool {
        lock.lock()
        defer { lock.unlock() }
        return file != nil
    }

    /// Set when the first write failed, so a broken capture is reported instead of
    /// silently producing an empty file.
    var failedWrite: Error? {
        lock.lock()
        defer { lock.unlock() }
        return writeError
    }

    func setPaused(_ isPaused: Bool) {
        lock.lock()
        defer { lock.unlock() }
        guard paused != isPaused else { return }
        paused = isPaused
        if isPaused {
            pausedAt = .now
        } else if let pausedAt {
            accumulated += Date.now.timeIntervalSince(pausedAt)
            self.pausedAt = nil
        }
    }

    func attach(_ continuation: AsyncStream<AudioMeterReading>.Continuation) {
        lock.lock()
        defer { lock.unlock() }
        self.continuation = continuation
    }

    /// Writes one buffer and returns the input level, or `nil` while paused.
    ///
    /// A write failure is latched into `writeError` rather than swallowed: a silently
    /// dropped buffer is indistinguishable from silence to the user, and used to
    /// produce a zero-frame `.m4a` that later failed transcription with no trace.
    func consume(_ buffer: AVReadOnlyAudioPCMBuffer) -> Float? {
        lock.lock()
        defer { lock.unlock() }

        guard !paused, let file else { return nil }

        if writeError == nil {
            do {
                try file.write(from: buffer)
            } catch {
                writeError = error
            }
        }

        guard case .float(let samples) = buffer.channelData(0) else { return nil }
        return Self.rms(samples, frameCount: buffer.frameLength)
    }

    func publish(level: Float) {
        lock.lock()
        let sink = continuation
        let elapsed = Date.now.timeIntervalSince(startedAt) - accumulated
        lock.unlock()

        sink?.yield(AudioMeterReading(level: min(1, max(0, level)), elapsed: elapsed))
    }

    /// Closes the capture and reports what was captured.
    ///
    /// The frame count is taken from the file, not the wall clock, so a capture that
    /// wrote nothing is reported as such instead of inheriting a plausible duration.
    func finish() -> (startedAt: Date, elapsed: TimeInterval, frameCount: Int64)? {
        lock.lock()
        defer { lock.unlock() }
        guard let file else { return nil }

        let frameCount = file.length
        let sampleRate = file.processingFormat.sampleRate
        let duration = sampleRate > 0 ? Double(frameCount) / sampleRate : 0

        let result = (startedAt: startedAt, elapsed: duration, frameCount: frameCount)
        self.file = nil
        return result
    }

    /// Releases the open file and ends the meter stream. Deleting the partial file is
    /// the caller's job, since only the actor knows the destination.
    func discard() {
        lock.lock()
        continuation?.finish()
        file = nil
        continuation = nil
        lock.unlock()
    }

    static func rms(_ samples: Span<Float>, frameCount: Int) -> Float {
        guard frameCount > 0, !samples.isEmpty else { return 0 }
        let count = min(frameCount, samples.count)
        var sum: Float = 0
        for index in 0..<count {
            let value = samples[index]
            sum += value * value
        }
        return sqrt(sum / Float(count))
    }
}

/// Microphone capture with `AVAudioEngine`.
///
/// Audio is written straight to an AAC file while it is recorded: no second pass, no
/// temp file, and a crash mid-recording still leaves a playable file on disk. Levels
/// are metered from the same tap to drive the live waveform.
public actor AudioEngineRecorder: AudioRecorder {
    private let engine = AVAudioEngine()
    private let session = CaptureSession()
    private var destination: AudioFileRef?
    private var tapInstalled = false

    public init() {}

    // MARK: - Authorization

    public func authorizationStatus() async -> AudioAuthorizationStatus {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: .authorized
        case .denied: .denied
        case .undetermined: .notDetermined
        @unknown default: .notDetermined
        }
    }

    @discardableResult
    public func requestAuthorization() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    // MARK: - Recording

    public func start(destination: AudioFileRef) async throws {
        guard !engine.isRunning, !session.isCapturing else { return }

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .spokenAudio, options: [.duckOthers, .allowBluetoothHFP])
        try audioSession.setActive(true)

        let input = engine.inputNode
        let hardware = input.outputFormat(forBus: 0)
        guard hardware.sampleRate > 0, hardware.channelCount > 0 else {
            throw TranscriptionError.audioUnreadable(reason: "no usable input format")
        }

        // One format for the whole capture. The engine converts from the hardware
        // format into this one, and the file is built with the same layout, so
        // `processingFormat == captureFormat` and the realtime write can never fail
        // on a channel or interleaving mismatch.
        guard let captureFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: hardware.sampleRate,
            channels: hardware.channelCount,
            interleaved: false
        ) else {
            throw TranscriptionError.audioUnreadable(reason: "no usable capture format")
        }

        try FileManager.default.createDirectory(
            at: destination.url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        // The meter sink is attached before the tap fires so no level is missed.
        let audioFile = try Self.makeFile(at: destination.url, format: captureFormat, requested: destination.format)
        let stream = Self.makeMeterStream()
        session.begin(file: audioFile, continuation: stream.continuation)
        self.destination = destination

        do {
            try input.installAudioTap(onBus: 0, bufferSize: 2048, format: captureFormat) { [session] buffer, _ in
                guard let level = session.consume(buffer) else { return }
                session.publish(level: level)
            }
            tapInstalled = true
        } catch {
            session.discard()
            self.destination = nil
            throw TranscriptionError.audioUnreadable(reason: "could not install the input tap: \(error)")
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            tearDown()
            try? FileManager.default.removeItem(at: destination.url)
            throw TranscriptionError.audioUnreadable(reason: "could not start the audio engine: \(error)")
        }
    }

    public func pause() async throws {
        guard engine.isRunning else { return }
        engine.pause()
        session.setPaused(true)
    }

    public func resume() async throws {
        // A resume is only valid while a capture is still open and the engine parked.
        guard !engine.isRunning, session.isCapturing else { return }
        session.setPaused(false)
        try engine.start()
    }

    public func stop() async throws -> AudioRecording {
        tearDown()

        guard let destination else {
            session.discard()
            throw TranscriptionError.emptyRecording
        }
        self.destination = nil

        if let failure = session.failedWrite {
            session.discard()
            try? FileManager.default.removeItem(at: destination.url)
            throw TranscriptionError.audioUnreadable(reason: "\(failure.localizedDescription)")
        }

        guard let finished = session.finish(), finished.frameCount > 0 else {
            session.discard()
            try? FileManager.default.removeItem(at: destination.url)
            throw TranscriptionError.emptyRecording
        }

        return AudioRecording(
            fileName: destination.url.lastPathComponent,
            duration: finished.elapsed,
            createdAt: finished.startedAt,
            format: destination.format
        )
    }

    public func cancel() async {
        let inFlight = destination
        tearDown()
        session.discard()
        self.destination = nil

        if let inFlight {
            try? FileManager.default.removeItem(at: inFlight.url)
        }
    }

    /// A fresh stream per capture. `AsyncStream` is single-consumer, so reusing one
    /// left the second recording with no meter updates at all.
    public func meter() async -> AsyncStream<AudioMeterReading> {
        let stream = Self.makeMeterStream()
        session.attach(stream.continuation)
        return stream.stream
    }

    /// Detaching a tap that was never installed raises an Objective-C exception, so
    /// every teardown path has to go through this flag.
    private func tearDown() {
        if tapInstalled {
            engine.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }
        if engine.isRunning { engine.stop() }
    }

    private static func makeMeterStream() -> (
        stream: AsyncStream<AudioMeterReading>,
        continuation: AsyncStream<AudioMeterReading>.Continuation
    ) {
        var continuation: AsyncStream<AudioMeterReading>.Continuation!
        let stream = AsyncStream<AudioMeterReading>(bufferingPolicy: .bufferingNewest(8)) {
            continuation = $0
        }
        return (stream, continuation)
    }

    /// AAC in an MPEG-4 container for `.m4a`; uncompressed for `.caf`.
    ///
    /// `format` is the capture format, never the hardware format, so the channel
    /// count and the PCM layout always match what the tap delivers.
    private static func makeFile(at url: URL, format: AVAudioFormat, requested: AudioFormat) throws -> AVAudioFile {
        let settings: [String: Any] = switch requested {
        case .m4a:
            [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: format.sampleRate,
                AVNumberOfChannelsKey: format.channelCount,
                AVEncoderBitRateKey: 96_000
            ]
        case .caf:
            [
                AVFormatIDKey: kAudioFormatLinearPCM,
                AVSampleRateKey: format.sampleRate,
                AVNumberOfChannelsKey: format.channelCount,
                AVLinearPCMBitDepthKey: 32,
                AVLinearPCMIsFloatKey: true,
                AVLinearPCMIsBigEndianKey: false,
                AVLinearPCMIsNonInterleaved: false
            ]
        }

        return try AVAudioFile(
            forWriting: url,
            settings: settings,
            commonFormat: format.commonFormat,
            interleaved: format.isInterleaved
        )
    }
}
