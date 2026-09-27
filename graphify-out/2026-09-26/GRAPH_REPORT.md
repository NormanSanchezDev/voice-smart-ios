# Graph Report - voice-smart-notes  (2026-09-26)

## Corpus Check
- 97 files · ~37,953 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1100 nodes · 2619 edges · 60 communities (54 shown, 6 thin omitted)
- Extraction: 89% EXTRACTED · 11% INFERRED · 0% AMBIGUOUS · INFERRED: 295 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `5b86e21d`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- NoteSmartUITests
- NoteSmartDomain
- VaultTag
- NoteSmartApp
- SwiftUI
- AppEnvironment
- .save
- NoteMarkdown
- VaultPath
- Note
- DSNoteCard
- AdaptiveColor
- TranscriptSegment
- AudioEngineRecorder
- Sendable
- RuleBasedNoteEnricher
- NoteError
- Design System
- DSButton
- Stage
- RTK Commands by Workflow
- .fileName
- View
- GlassConfig
- NoteCardModel
- Task
- Motion
- Spacing.swift
- NoteEditorViewModel
- .decode
- .transcribe
- .prose
- ADR 0001 — Arquitectura en capas y reglas de dependencia
- ADR 0002 — El vault markdown es la fuente de verdad
- ADR 0003 — IA on-device con piso determinista
- DSEmptyState
- ADR 0004 — Liquid Glass sólo en el chrome
- ADR 0005 — Local-first sin autenticación
- Typography
- AGENTS.md
- PackageDescription
- State
- Foundation
- EnrichmentProgress
- AudioFileRef
- NoteFrontmatter
- Transcriber
- Testing
- .enrich
- NoteID
- AIAvailability
- Stage
- TimeRange
- AudioFormat
- AudioAuthorizationStatus
- SystemDateProvider
- ModelInstallProgress
- ValueObjectTests
- .consume
- AudioEngineRecorder.swift

## God Nodes (most connected - your core abstractions)
1. `Note` - 63 edges
2. `VaultPath` - 56 edges
3. `VaultTag` - 45 edges
4. `FileNoteRepository` - 43 edges
5. `NoteID` - 43 edges
6. `AppEnvironment` - 36 edges
7. `NoteEditorViewModel` - 34 edges
8. `TranscriptSegment` - 32 edges
9. `Task` - 32 edges
10. `RecordViewModel` - 28 edges

## Surprising Connections (you probably didn't know these)
- `.transcriptPreview` --calls--> `DSCard`  [INFERRED]
  NoteSmart/NoteSmart/Presentation/Features/Record/RecordPanel.swift → Packages/NoteSmartDesignSystem/Sources/DSAtoms/DSCard.swift
- `.body` --calls--> `DSEmptyState`  [INFERRED]
  NoteSmart/NoteSmart/Presentation/AppRootView.swift → Packages/NoteSmartDesignSystem/Sources/DSMolecules/DSEmptyState.swift
- `.body` --calls--> `Task`  [INFERRED]
  NoteSmart/NoteSmart/Presentation/AppRootView.swift → Packages/NoteSmartDomain/Sources/UseCases/MarkdownEditing.swift
- `.body` --calls--> `DSReadingColumn`  [INFERRED]
  NoteSmart/NoteSmart/Presentation/Features/NoteEditor/NoteEditorView.swift → Packages/NoteSmartDesignSystem/Sources/DSTemplates/DSReadingColumn.swift
- `.body` --calls--> `Task`  [INFERRED]
  NoteSmart/NoteSmart/Presentation/Features/NoteEditor/NoteEditorView.swift → Packages/NoteSmartDomain/Sources/UseCases/MarkdownEditing.swift

## Import Cycles
- None detected.

## Communities (60 total, 6 thin omitted)

### Community 0 - "NoteSmartUITests"
Cohesion: 0.25
Nodes (3): NoteSmartUITests, XCTest, XCTestCase

### Community 1 - "NoteSmartDomain"
Cohesion: 0.22
Nodes (5): DSOrganisms, NoteSmart, NoteSmartDomain, Observation, SwiftData

### Community 2 - "VaultTag"
Cohesion: 0.17
Nodes (10): Comparable, NoteEnrichmentDraft, AsyncThrowingStream, Error, Locale, String, String, VaultTag (+2 more)

### Community 3 - "NoteSmartApp"
Cohesion: 0.40
Nodes (4): App, NoteSmartApp, .body, Scene

### Community 4 - "SwiftUI"
Cohesion: 0.24
Nodes (5): DSAtoms, DSMolecules, DSTemplates, DSTokens, SwiftUI

### Community 5 - "AppEnvironment"
Cohesion: 0.13
Nodes (14): ModelContext, AppEnvironment, ModelContainer, AppRootView, .body, String, OnDeviceNoteEnricher, .availability (+6 more)

### Community 6 - ".save"
Cohesion: 0.16
Nodes (12): NoteTitleKey, Bool, Double, String, Sandbox, String, TimeInterval, URL (+4 more)

### Community 7 - "NoteMarkdown"
Cohesion: 0.24
Nodes (6): Key, NoteMarkdown, Date, Double, Int, String

### Community 8 - "VaultPath"
Cohesion: 0.09
Nodes (22): DocumentsVaultLocator, FileManager, URL, FileNoteRepository, .rootURL, NoteIndexWriting, FileManager, String (+14 more)

### Community 9 - "Note"
Cohesion: 0.11
Nodes (12): .activeSegmentID, Note, .isEditedByAI, .relativePath, .tags, .title, .transcriptText, Bool (+4 more)

### Community 10 - "DSNoteCard"
Cohesion: 0.07
Nodes (37): CGRect, CGSize, Layout, DSBadge, .body, DSChip, String, Void (+29 more)

### Community 11 - "AdaptiveColor"
Cohesion: 0.07
Nodes (32): EnvironmentValues, .body, DSAudioLevelMeter, .body, DSProgressBar, .body, Bool, Double (+24 more)

### Community 12 - "TranscriptSegment"
Cohesion: 0.28
Nodes (9): Bool, Double, String, UUID, TranscriptionProgress, .displayText, TranscriptSegment, .isFinal (+1 more)

### Community 13 - "AudioEngineRecorder"
Cohesion: 0.15
Nodes (12): AsyncStream, AVAudioFile, AVAudioFormat, AudioEngineRecorder, CaptureSession, .isCapturing, Bool, Date (+4 more)

### Community 14 - "Sendable"
Cohesion: 0.30
Nodes (9): DateProvider, NoteEnricher, NoteRepository, CreateNoteFromRecording, Output, String, MoveNote, RenameNote (+1 more)

### Community 15 - "RuleBasedNoteEnricher"
Cohesion: 0.12
Nodes (8): RuleBasedNoteEnricher, .availability, AsyncThrowingStream, Error, Locale, String, String, RuleBasedNoteEnricherTests

### Community 16 - "NoteError"
Cohesion: 0.08
Nodes (28): Equatable, Error, Mode, editing, reading, EnrichmentError, cancelled, contextWindowExceeded (+20 more)

### Community 17 - "Design System"
Cohesion: 0.07
Nodes (29): ADRs, Arquitectura, Documentos, Modelo de dominio, Paquetes, Archivos, Capa de datos, Detalles que no son evidentes (+21 more)

### Community 18 - "DSButton"
Cohesion: 0.13
Nodes (18): ButtonStyle, Configuration, Label, DSButton, .body, DSButtonKind, destructive, glass (+10 more)

### Community 19 - "Stage"
Cohesion: 0.14
Nodes (17): DSRecordingPanel, Stage, done, enriching, failed, .isFailure, .progress, recording (+9 more)

### Community 20 - "RTK Commands by Workflow"
Cohesion: 0.13
Nodes (14): Analysis & Debug (70-90% savings), Build & Compile (80-90% savings), Files & Search (60-75% savings), Git (59-80% savings), GitHub (26-87% savings), Golden Rule, Infrastructure (85% savings), JavaScript/TypeScript Tooling (70-90% savings) (+6 more)

### Community 21 - ".fileName"
Cohesion: 0.23
Nodes (4): NoteFileNaming, Bool, String, NoteFileNamingTests

### Community 22 - "View"
Cohesion: 0.17
Nodes (14): AnyView, CGFloat, View, DSFloatingToolbar, .body, DSListScaffold, .body, .floatingBar (+6 more)

### Community 23 - "GlassConfig"
Cohesion: 0.12
Nodes (14): DSGlassModifier, Content, Emphasis, accent, danger, neutral, GlassConfig, .cornerRadius (+6 more)

### Community 24 - "NoteCardModel"
Cohesion: 0.08
Nodes (21): NotesListView, .body, .cards, .emptyState, .list, String, NotesListViewModel, .cards (+13 more)

### Community 25 - "Task"
Cohesion: 0.05
Nodes (34): AVPlayer, AudioPlaybackController, .isLoaded, .progress, Bool, Double, Never, TimeInterval (+26 more)

### Community 26 - "Motion"
Cohesion: 0.25
Nodes (6): Animation, Duration, Motion, Spring, Bool, Double

### Community 27 - "Spacing.swift"
Cohesion: 0.29
Nodes (6): CoreGraphics, Metrics, CGFloat, Radius, Spacing, CGFloat

### Community 28 - "NoteEditorViewModel"
Cohesion: 0.06
Nodes (41): AttributedString, Binding, Error, String, NoteEditorScreen, .audioSection, .body, .header (+33 more)

### Community 30 - ".transcribe"
Cohesion: 0.32
Nodes (6): OnDeviceTranscriber, AsyncThrowingStream, Bool, Error, Locale, SpeechTranscriber

### Community 31 - ".prose"
Cohesion: 0.27
Nodes (4): NoteBody, Bool, String, NoteBodyTests

### Community 32 - "ADR 0001 — Arquitectura en capas y reglas de dependencia"
Cohesion: 0.29
Nodes (6): ADR 0001 — Arquitectura en capas y reglas de dependencia, Consecuencias, Contexto, Decisión, Reglas de dependencia, Ver también

### Community 33 - "ADR 0002 — El vault markdown es la fuente de verdad"
Cohesion: 0.29
Nodes (6): ADR 0002 — El vault markdown es la fuente de verdad, Consecuencias, Contexto, Decisión, Frontmatter plano y deliberadamente pequeño, Ver también

### Community 34 - "ADR 0003 — IA on-device con piso determinista"
Cohesion: 0.29
Nodes (6): ADR 0003 — IA on-device con piso determinista, Consecuencias, Contexto, Decisión, Reglas del prompt, Ver también

### Community 35 - "DSEmptyState"
Cohesion: 0.33
Nodes (7): DSEmptyState, .body, DSSectionHeader, .body, String, Void, Trailing

### Community 36 - "ADR 0004 — Liquid Glass sólo en el chrome"
Cohesion: 0.33
Nodes (5): ADR 0004 — Liquid Glass sólo en el chrome, Contexto, Decisión, Por qué `GlassConfig` y no `Glass`, Ver también

### Community 37 - "ADR 0005 — Local-first sin autenticación"
Cohesion: 0.33
Nodes (5): ADR 0005 — Local-first sin autenticación, Consecuencias, Contexto, Decisión, Ver también

### Community 38 - "Typography"
Cohesion: 0.38
Nodes (4): Font, .editingBody, CGFloat, Typography

### Community 41 - "State"
Cohesion: 0.40
Nodes (5): State, failed, preparing, ready, String

### Community 42 - "Foundation"
Cohesion: 0.13
Nodes (4): AVFoundation, Foundation, FoundationModels, AppErrorMessage

### Community 43 - "EnrichmentProgress"
Cohesion: 0.14
Nodes (14): EnrichmentProgress, EnrichmentSource, .isAI, onDeviceAI, ruleBasedFallback, NoteEnrichment, Bool, String (+6 more)

### Community 44 - "AudioFileRef"
Cohesion: 0.26
Nodes (9): AudioFileRef, Locale, URL, CreateNoteFromRecordingTests, FailingEnricher, InMemoryNoteRepository, StubEnricher, StubTranscriber (+1 more)

### Community 45 - "NoteFrontmatter"
Cohesion: 0.22
Nodes (13): Codable, AudioRef, NoteFrontmatter, NoteSource, imported, manual, voice, Bool (+5 more)

### Community 46 - "Transcriber"
Cohesion: 0.25
Nodes (8): Transcriber, Stage, finished, installing, transcribing, AsyncThrowingStream, Error, TranscribeRecording

### Community 48 - ".enrich"
Cohesion: 0.23
Nodes (5): AsyncThrowingStream, Bool, Error, Locale, String

### Community 49 - "NoteID"
Cohesion: 0.08
Nodes (28): CustomStringConvertible, Hashable, Identifiable, NoteIndexRecord, .noteID, .tagValues, Bool, Date (+20 more)

### Community 50 - "AIAvailability"
Cohesion: 0.20
Nodes (9): AIAvailability, available, .isAvailable, unavailable, AIUnavailableReason, deviceNotEligible, modelNotReady, regionNotSupported (+1 more)

### Community 51 - "Stage"
Cohesion: 0.40
Nodes (5): Stage, enriching, installingModel, saved, transcribing

### Community 52 - "TimeRange"
Cohesion: 0.23
Nodes (6): Bool, String, TimeInterval, TimeRange, .duration, .isEmpty

### Community 53 - "AudioFormat"
Cohesion: 0.33
Nodes (7): CaseIterable, AudioFormat, caf, m4a, AudioRecording, Date, TimeInterval

### Community 54 - "AudioAuthorizationStatus"
Cohesion: 0.29
Nodes (5): AudioAuthorizationStatus, authorized, denied, notDetermined, AudioRecorder

### Community 55 - "SystemDateProvider"
Cohesion: 0.38
Nodes (4): FixedDateProvider, Date, SystemDateProvider, .now

### Community 56 - "ModelInstallProgress"
Cohesion: 0.83
Nodes (3): ModelInstallProgress, Bool, Double

### Community 58 - ".consume"
Cohesion: 0.40
Nodes (4): AVReadOnlyAudioPCMBuffer, Float, Int, Span

## Knowledge Gaps
- **199 isolated node(s):** `preparing`, `ready`, `failed`, `AVFoundation`, `.progress` (+194 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **6 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Note` connect `Note` to `VaultTag`, `AppEnvironment`, `.save`, `NoteMarkdown`, `VaultPath`, `Foundation`, `TranscriptSegment`, `NoteFrontmatter`, `Sendable`, `AudioFileRef`, `.enrich`, `NoteID`, `Stage`, `NoteCardModel`, `Task`, `NoteEditorViewModel`, `.decode`?**
  _High betweenness centrality (0.125) - this node is a cross-community bridge._
- **Why does `View` connect `View` to `DSEmptyState`, `AppEnvironment`, `DSNoteCard`, `AdaptiveColor`, `DSButton`, `Stage`, `GlassConfig`, `NoteCardModel`, `Task`, `NoteEditorViewModel`?**
  _High betweenness centrality (0.093) - this node is a cross-community bridge._
- **Why does `VaultTag` connect `VaultTag` to `.save`, `VaultPath`, `Note`, `Foundation`, `EnrichmentProgress`, `AudioFileRef`, `NoteFrontmatter`, `Sendable`, `RuleBasedNoteEnricher`, `.enrich`, `NoteID`, `Task`, `NoteEditorViewModel`, `ValueObjectTests`?**
  _High betweenness centrality (0.079) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `Note` (e.g. with `.addTag()` and `.removeTag()`) actually correct?**
  _`Note` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 12 inferred relationships involving `VaultPath` (e.g. with `.makeNote()` and `.search()`) actually correct?**
  _`VaultPath` has 12 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `VaultTag` (e.g. with `.tagsRow()` and `.inlineTags()`) actually correct?**
  _`VaultTag` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `preparing`, `ready`, `failed` to the rest of the system?**
  _199 weakly-connected nodes found - possible documentation gaps or missing edges._