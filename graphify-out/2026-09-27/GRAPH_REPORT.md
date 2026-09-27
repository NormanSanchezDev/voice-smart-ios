# Graph Report - voice-smart-notes  (2026-09-27)

## Corpus Check
- 103 files · ~42,930 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1163 nodes · 2746 edges · 52 communities (50 shown, 2 thin omitted)
- Extraction: 88% EXTRACTED · 12% INFERRED · 0% AMBIGUOUS · INFERRED: 318 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `5b86e21d`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- NoteSmartUITests
- Foundation
- AIAvailability
- AudioFileRef
- SwiftUI
- AdaptiveColor
- .save
- TranscriptSegment
- VaultPath
- Note
- DSNoteCard
- DSRecordingButton
- NoteID
- AudioEngineRecorder
- .enrich
- RuleBasedNoteEnricher
- NoteError
- Testing
- DSButton
- Palette
- RTK Commands by Workflow
- .fileName
- DSListScaffold
- GlassConfig
- NoteCardModel
- AppEnvironment
- SplashView
- Spacing.swift
- NoteEditorViewModel
- Task
- RecordingsListView
- ADR 0001 — Arquitectura en capas y reglas de dependencia
- ADR 0002 — El vault markdown es la fuente de verdad
- ADR 0003 — IA on-device con piso determinista
- DSEmptyState
- ADR 0004 — Liquid Glass sólo en el chrome
- ADR 0005 — Local-first sin autenticación
- AGENTS.md
- PackageDescription
- RecordHomeView
- EnrichmentProgress
- NoteFrontmatter
- ProfileView
- View
- Hashable
- DSCard
- .callAsFunction
- DSAudioLevelMeter
- Sendable
- DSReadingColumn
- VaultTag

## God Nodes (most connected - your core abstractions)
1. `Note` - 63 edges
2. `VaultPath` - 56 edges
3. `VaultTag` - 45 edges
4. `FileNoteRepository` - 43 edges
5. `NoteID` - 43 edges
6. `AppEnvironment` - 40 edges
7. `NoteEditorViewModel` - 34 edges
8. `Task` - 33 edges
9. `TranscriptSegment` - 32 edges
10. `NoteSmartDomain` - 29 edges

## Surprising Connections (you probably didn't know these)
- `.footer` --calls--> `DSButton`  [INFERRED]
  NoteSmart/NoteSmart/Presentation/Features/Splash/SplashView.swift → Packages/NoteSmartDesignSystem/Sources/DSAtoms/DSButton.swift
- `.body` --calls--> `DSEmptyState`  [INFERRED]
  NoteSmart/NoteSmart/Presentation/AppRootView.swift → Packages/NoteSmartDesignSystem/Sources/DSMolecules/DSEmptyState.swift
- `.body` --calls--> `Task`  [INFERRED]
  NoteSmart/NoteSmart/Presentation/AppRootView.swift → Packages/NoteSmartDomain/Sources/UseCases/MarkdownEditing.swift
- `.body` --calls--> `DSCard`  [INFERRED]
  NoteSmart/NoteSmart/Presentation/Features/More/MoreView.swift → Packages/NoteSmartDesignSystem/Sources/DSAtoms/DSCard.swift
- `.body` --calls--> `DSSectionHeader`  [INFERRED]
  NoteSmart/NoteSmart/Presentation/Features/More/MoreView.swift → Packages/NoteSmartDesignSystem/Sources/DSMolecules/DSEmptyState.swift

## Import Cycles
- None detected.

## Communities (52 total, 2 thin omitted)

### Community 0 - "NoteSmartUITests"
Cohesion: 0.25
Nodes (3): NoteSmartUITests, XCTest, XCTestCase

### Community 1 - "Foundation"
Cohesion: 0.08
Nodes (16): AVFAudio, AVFoundation, DSOrganisms, Foundation, FoundationModels, NoteSmart, NoteBody, Bool (+8 more)

### Community 2 - "AIAvailability"
Cohesion: 0.13
Nodes (16): NoteEnrichmentDraft, OnDeviceNoteEnricher, .availability, AsyncThrowingStream, Error, Locale, String, AIAvailability (+8 more)

### Community 3 - "AudioFileRef"
Cohesion: 0.26
Nodes (9): AudioFileRef, Locale, URL, CreateNoteFromRecordingTests, FailingEnricher, InMemoryNoteRepository, StubEnricher, StubTranscriber (+1 more)

### Community 4 - "SwiftUI"
Cohesion: 0.23
Nodes (5): DSAtoms, DSMolecules, DSTemplates, DSTokens, SwiftUI

### Community 5 - "AdaptiveColor"
Cohesion: 0.31
Nodes (6): EnvironmentValues, AdaptiveColor, Color, ShapeStyle, Double, UInt32

### Community 6 - ".save"
Cohesion: 0.11
Nodes (22): ModelContext, NoteIndexRecord, .noteID, .tagValues, Bool, Date, Double, Int (+14 more)

### Community 7 - "TranscriptSegment"
Cohesion: 0.06
Nodes (29): Key, NoteMarkdown, Date, Double, Int, String, OnDeviceTranscriber, AsyncThrowingStream (+21 more)

### Community 8 - "VaultPath"
Cohesion: 0.08
Nodes (23): DocumentsVaultLocator, URL, FileNoteRepository, .rootURL, NoteIndexWriting, FileManager, String, URL (+15 more)

### Community 9 - "Note"
Cohesion: 0.12
Nodes (11): .activeSegmentID, Note, .isEditedByAI, .relativePath, .tags, .title, .transcriptText, Bool (+3 more)

### Community 10 - "DSNoteCard"
Cohesion: 0.07
Nodes (37): CGRect, CGSize, Layout, DSBadge, .body, DSChip, String, Void (+29 more)

### Community 11 - "DSRecordingButton"
Cohesion: 0.15
Nodes (16): DSRecordingButton, .body, .innerDisc, DSRecordingButton.State, .accessibilityHint, .accessibilityLabel, .fillColor, .isRecording (+8 more)

### Community 12 - "NoteID"
Cohesion: 0.19
Nodes (8): CustomStringConvertible, RecordingIndexSpy, .lastIndexed, .lastRemoved, NoteID, .description, String, UUID

### Community 13 - "AudioEngineRecorder"
Cohesion: 0.09
Nodes (21): AsyncStream, AVAudioFile, AVAudioFormat, AVReadOnlyAudioPCMBuffer, AudioEngineRecorder, CaptureSession, .failedWrite, .isCapturing (+13 more)

### Community 14 - ".enrich"
Cohesion: 0.23
Nodes (5): AsyncThrowingStream, Bool, Error, Locale, String

### Community 15 - "RuleBasedNoteEnricher"
Cohesion: 0.12
Nodes (8): RuleBasedNoteEnricher, .availability, AsyncThrowingStream, Error, Locale, String, String, RuleBasedNoteEnricherTests

### Community 16 - "NoteError"
Cohesion: 0.05
Nodes (45): Equatable, Error, Mode, editing, reading, DSRecordingPanel, Stage, done (+37 more)

### Community 17 - "Testing"
Cohesion: 0.05
Nodes (36): ADRs, Arquitectura, Documentos, Modelo de dominio, Paquetes, Archivos, Capa de datos, Detalles que no son evidentes (+28 more)

### Community 18 - "DSButton"
Cohesion: 0.14
Nodes (17): ButtonStyle, Configuration, Label, DSButton, .body, DSButtonKind, destructive, glass (+9 more)

### Community 19 - "Palette"
Cohesion: 0.40
Nodes (4): .body, .body, .outerRing, Palette

### Community 20 - "RTK Commands by Workflow"
Cohesion: 0.13
Nodes (14): Analysis & Debug (70-90% savings), Build & Compile (80-90% savings), Files & Search (60-75% savings), Git (59-80% savings), GitHub (26-87% savings), Golden Rule, Infrastructure (85% savings), JavaScript/TypeScript Tooling (70-90% savings) (+6 more)

### Community 21 - ".fileName"
Cohesion: 0.26
Nodes (4): NoteFileNaming, Bool, String, NoteFileNamingTests

### Community 22 - "DSListScaffold"
Cohesion: 0.31
Nodes (8): AnyView, DSFloatingToolbar, .body, DSListScaffold, .floatingBar, Bool, Content, String

### Community 23 - "GlassConfig"
Cohesion: 0.12
Nodes (15): DSGlassModifier, Content, Emphasis, accent, danger, neutral, GlassConfig, .cornerRadius (+7 more)

### Community 24 - "NoteCardModel"
Cohesion: 0.19
Nodes (9): NoteCardModel, Date, Int, String, TimeInterval, NoteCardModelTests, Bool, String (+1 more)

### Community 25 - "AppEnvironment"
Cohesion: 0.06
Nodes (32): AppEnvironment, State, failed, preparing, ready, ModelContainer, String, .captureScreen (+24 more)

### Community 26 - "SplashView"
Cohesion: 0.07
Nodes (26): Animation, App, NoteSmartApp, .body, AppRootView, .body, String, Phase (+18 more)

### Community 27 - "Spacing.swift"
Cohesion: 0.29
Nodes (6): CoreGraphics, Metrics, CGFloat, Radius, Spacing, CGFloat

### Community 28 - "NoteEditorViewModel"
Cohesion: 0.05
Nodes (40): AttributedString, Binding, Font, AppErrorMessage, Error, String, NoteEditorScreen, .audioSection (+32 more)

### Community 29 - "Task"
Cohesion: 0.09
Nodes (17): AVPlayer, AudioPlaybackController, .isLoaded, .progress, Bool, Double, Never, TimeInterval (+9 more)

### Community 31 - "RecordingsListView"
Cohesion: 0.17
Nodes (9): RecordingsListView, .body, .cards, .list, String, RecordingsListViewModel, .cards, String (+1 more)

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
Cohesion: 0.29
Nodes (8): .emptyState, DSEmptyState, .body, DSSectionHeader, .body, String, Void, Trailing

### Community 36 - "ADR 0004 — Liquid Glass sólo en el chrome"
Cohesion: 0.33
Nodes (5): ADR 0004 — Liquid Glass sólo en el chrome, Contexto, Decisión, Por qué `GlassConfig` y no `Glass`, Ver también

### Community 37 - "ADR 0005 — Local-first sin autenticación"
Cohesion: 0.29
Nodes (6): ADR 0005 — Local-first sin autenticación, Consecuencias, Contexto, Decisión, Reconsideración: qué significa "Cerrar sesión", Ver también

### Community 41 - "RecordHomeView"
Cohesion: 0.22
Nodes (12): RecordHomeView, .body, .caption, .captionText, .toolbar, Route, more, note (+4 more)

### Community 43 - "EnrichmentProgress"
Cohesion: 0.15
Nodes (15): EnrichmentProgress, EnrichmentSource, .isAI, onDeviceAI, ruleBasedFallback, NoteEnricher, NoteEnrichment, Bool (+7 more)

### Community 45 - "NoteFrontmatter"
Cohesion: 0.17
Nodes (17): CaseIterable, Codable, AudioFormat, caf, m4a, AudioRecording, Date, AudioRef (+9 more)

### Community 47 - "ProfileView"
Cohesion: 0.29
Nodes (8): ProfileView, .body, .vaultDescription, .versionDescription, Int, Int64, String, VaultUsage

### Community 48 - "View"
Cohesion: 0.31
Nodes (7): ButtonRole, MoreView, .body, String, Void, CGFloat, View

### Community 49 - "Hashable"
Cohesion: 0.25
Nodes (11): Hashable, Identifiable, Edge, .id, Node, NoteGraph, NoteSearchResult, .id (+3 more)

### Community 50 - "DSCard"
Cohesion: 0.36
Nodes (6): DSCard, .body, DSSeparator, .body, CGFloat, Content

### Community 51 - ".callAsFunction"
Cohesion: 0.19
Nodes (10): CreateNoteFromRecording, Output, Stage, enriching, installingModel, saved, transcribing, AsyncThrowingStream (+2 more)

### Community 53 - "DSAudioLevelMeter"
Cohesion: 0.36
Nodes (6): DSAudioLevelMeter, DSProgressBar, .body, Bool, Double, .body

### Community 54 - "Sendable"
Cohesion: 0.12
Nodes (19): GraphBuilding, NoteSearch, AudioAuthorizationStatus, authorized, denied, notDetermined, AudioRecorder, ModelInstallProgress (+11 more)

### Community 55 - "DSReadingColumn"
Cohesion: 0.50
Nodes (4): .body, DSReadingColumn, .body, Content

### Community 56 - "VaultTag"
Cohesion: 0.23
Nodes (8): Comparable, String, VaultTag, .description, .displayText, SearchScope, Bool, Set

## Knowledge Gaps
- **221 isolated node(s):** `preparing`, `ready`, `failed`, `.vaultDescription`, `.versionDescription` (+216 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `View` connect `View` to `DSEmptyState`, `RecordHomeView`, `DSNoteCard`, `DSRecordingButton`, `ProfileView`, `NoteError`, `DSButton`, `DSCard`, `DSAudioLevelMeter`, `DSListScaffold`, `GlassConfig`, `DSReadingColumn`, `SplashView`, `NoteEditorViewModel`, `RecordingsListView`?**
  _High betweenness centrality (0.130) - this node is a cross-community bridge._
- **Why does `Note` connect `Note` to `AudioFileRef`, `.save`, `TranscriptSegment`, `VaultPath`, `NoteID`, `NoteFrontmatter`, `.enrich`, `Hashable`, `.callAsFunction`, `Sendable`, `NoteCardModel`, `AppEnvironment`, `VaultTag`, `NoteEditorViewModel`, `RecordingsListView`?**
  _High betweenness centrality (0.122) - this node is a cross-community bridge._
- **Why does `NoteID` connect `NoteID` to `.save`, `TranscriptSegment`, `VaultPath`, `RecordHomeView`, `Note`, `NoteFrontmatter`, `.enrich`, `NoteError`, `Hashable`, `Sendable`, `NoteCardModel`, `NoteEditorViewModel`, `RecordingsListView`?**
  _High betweenness centrality (0.080) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `Note` (e.g. with `.addTag()` and `.removeTag()`) actually correct?**
  _`Note` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 12 inferred relationships involving `VaultPath` (e.g. with `.makeNote()` and `.search()`) actually correct?**
  _`VaultPath` has 12 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `VaultTag` (e.g. with `.tagsRow()` and `.inlineTags()`) actually correct?**
  _`VaultTag` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `preparing`, `ready`, `failed` to the rest of the system?**
  _221 weakly-connected nodes found - possible documentation gaps or missing edges._