# Graph Report - voice-smart-notes  (2026-09-27)

## Corpus Check
- 107 files · ~51,462 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1228 nodes · 2817 edges · 67 communities (65 shown, 2 thin omitted)
- Extraction: 89% EXTRACTED · 11% INFERRED · 0% AMBIGUOUS · INFERRED: 318 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `b7519928`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- NoteSmartUITests
- Foundation
- OnDeviceNoteEnricher
- AudioFileRef
- SwiftUI
- NoteSmart
- .save
- TranscriptSegment
- FileNoteRepository
- Note
- DSNoteCard
- AdaptiveColor
- Añadido
- AudioEngineRecorder
- VaultTag
- RuleBasedNoteEnricher
- Stage
- Testing
- DSButton
- AIAvailability
- RTK Commands by Workflow
- .fileName
- DSListScaffold
- GlassConfig
- NoteCardModel
- RecordViewModel
- SplashView
- Spacing.swift
- NoteEditorViewModel
- Task
- Equatable
- ADR 0001 — Arquitectura en capas y reglas de dependencia
- ADR 0002 — El vault markdown es la fuente de verdad
- ADR 0003 — IA on-device con piso determinista
- DSEmptyState
- ADR 0004 — Liquid Glass sólo en el chrome
- ADR 0005 — Local-first sin autenticación
- DSIconButton
- AGENTS.md
- PackageDescription
- RecordHomeView
- DSChip
- NoteEnricher
- NoteError
- VaultPath
- EnrichmentError
- ProfileView
- View
- Sendable
- DSCard
- .callAsFunction
- TranscriptionError
- Palette
- Transcriber
- DSTextField
- Capa de datos
- Design System
- Typography
- .text
- DSRecordingPanel
- Presentación
- State
- Arquitectura

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
- `.body` --calls--> `DSSectionHeader`  [INFERRED]
  NoteSmart/NoteSmart/Presentation/Features/More/MoreView.swift → Packages/NoteSmartDesignSystem/Sources/DSMolecules/DSEmptyState.swift
- `.body` --calls--> `DSListScaffold`  [INFERRED]
  NoteSmart/NoteSmart/Presentation/Features/More/MoreView.swift → Packages/NoteSmartDesignSystem/Sources/DSTemplates/DSListScaffold.swift
- `.body` --calls--> `DSButton`  [INFERRED]
  NoteSmart/NoteSmart/Presentation/Features/More/ProfileView.swift → Packages/NoteSmartDesignSystem/Sources/DSAtoms/DSButton.swift

## Import Cycles
- None detected.

## Communities (67 total, 2 thin omitted)

### Community 0 - "NoteSmartUITests"
Cohesion: 0.25
Nodes (3): NoteSmartUITests, XCTest, XCTestCase

### Community 1 - "Foundation"
Cohesion: 0.09
Nodes (15): AVFAudio, AVFoundation, DSOrganisms, Foundation, NoteSmart, NoteBody, Bool, String (+7 more)

### Community 2 - "OnDeviceNoteEnricher"
Cohesion: 0.22
Nodes (8): FoundationModels, NoteEnrichmentDraft, OnDeviceNoteEnricher, .availability, AsyncThrowingStream, Error, Locale, String

### Community 3 - "AudioFileRef"
Cohesion: 0.21
Nodes (11): AudioFileRef, Locale, URL, EnrichmentProgress, CreateNoteFromRecordingTests, EnrichTranscriptTests, FailingEnricher, InMemoryNoteRepository (+3 more)

### Community 4 - "SwiftUI"
Cohesion: 0.21
Nodes (5): DSAtoms, DSMolecules, DSTemplates, DSTokens, SwiftUI

### Community 5 - "NoteSmart"
Cohesion: 0.05
Nodes (41): Antes de abrir un PR, Arquitectura, Búsqueda, Capa de datos, Captura, Captura de audio, Capturas, Cobertura (+33 more)

### Community 6 - ".save"
Cohesion: 0.09
Nodes (28): ModelContext, NoteIndexRecord, .noteID, .tagValues, Bool, Date, Double, Int (+20 more)

### Community 7 - "TranscriptSegment"
Cohesion: 0.08
Nodes (24): .activeSegmentID, OnDeviceTranscriber, AsyncThrowingStream, Bool, Error, Locale, TimeInterval, Bool (+16 more)

### Community 8 - "FileNoteRepository"
Cohesion: 0.08
Nodes (25): AppEnvironment, ModelContainer, DocumentsVaultLocator, FileManager, URL, FileNoteRepository, .rootURL, NoteIndexWriting (+17 more)

### Community 9 - "Note"
Cohesion: 0.09
Nodes (16): RecordingIndexSpy, .lastIndexed, .lastRemoved, Note, .isEditedByAI, .relativePath, .tags, .title (+8 more)

### Community 10 - "DSNoteCard"
Cohesion: 0.09
Nodes (30): CGRect, CGSize, Layout, DSBadge, .body, Tone, accent, .color (+22 more)

### Community 11 - "AdaptiveColor"
Cohesion: 0.11
Nodes (22): EnvironmentValues, DSRecordingButton, .body, .innerDisc, DSRecordingButton.State, .accessibilityHint, .accessibilityLabel, .fillColor (+14 more)

### Community 12 - "Añadido"
Cohesion: 0.10
Nodes (20): [1.0.0] — 2026-09-27, Arquitectura, Audio, Añadido, Añadido — resumen numérico, Build, Changelog, Corregido (+12 more)

### Community 13 - "AudioEngineRecorder"
Cohesion: 0.09
Nodes (20): AsyncStream, AVAudioFile, AVAudioFormat, AVReadOnlyAudioPCMBuffer, AudioEngineRecorder, CaptureSession, .failedWrite, .isCapturing (+12 more)

### Community 14 - "VaultTag"
Cohesion: 0.16
Nodes (10): Comparable, CustomStringConvertible, String, VaultTag, .description, .displayText, AsyncThrowingStream, Bool (+2 more)

### Community 15 - "RuleBasedNoteEnricher"
Cohesion: 0.12
Nodes (8): RuleBasedNoteEnricher, .availability, AsyncThrowingStream, Error, Locale, String, String, RuleBasedNoteEnricherTests

### Community 16 - "Stage"
Cohesion: 0.15
Nodes (13): Stage, done, enriching, failed, .isFailure, .progress, recording, saving (+5 more)

### Community 17 - "Testing"
Cohesion: 0.18
Nodes (11): Bloqueo conocido en esta máquina, Cobertura honesta de la navegación, Compilar sin correr, La ruta que funciona: tests en un iPhone real, `NoteSmartData` es iOS-only, y lo dice, Por qué el dominio corre en el Mac, Qué cubren los tests, Testing (+3 more)

### Community 18 - "DSButton"
Cohesion: 0.14
Nodes (17): ButtonStyle, Configuration, Label, DSButton, .body, DSButtonKind, destructive, glass (+9 more)

### Community 19 - "AIAvailability"
Cohesion: 0.14
Nodes (14): AIAvailability, available, .isAvailable, unavailable, AIUnavailableReason, deviceNotEligible, modelNotReady, regionNotSupported (+6 more)

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
Cohesion: 0.09
Nodes (19): RecordingsListView, .body, .cards, .emptyState, .list, String, RecordingsListViewModel, .cards (+11 more)

### Community 25 - "RecordViewModel"
Cohesion: 0.16
Nodes (9): RecordViewModel, .buttonState, .isBusy, .panel, Bool, Double, Never, TimeInterval (+1 more)

### Community 26 - "SplashView"
Cohesion: 0.17
Nodes (10): SplashView, .body, .footer, .mark, .subtitle, .wordmark, String, Void (+2 more)

### Community 27 - "Spacing.swift"
Cohesion: 0.29
Nodes (6): CoreGraphics, Metrics, CGFloat, Radius, Spacing, CGFloat

### Community 28 - "NoteEditorViewModel"
Cohesion: 0.18
Nodes (10): NoteEditorView, .body, NoteEditorViewModel, .canSave, .hasTranscript, .prose, .tasks, Bool (+2 more)

### Community 29 - "Task"
Cohesion: 0.05
Nodes (30): Animation, App, AVPlayer, NoteSmartApp, .body, AppRootView, .body, String (+22 more)

### Community 31 - "Equatable"
Cohesion: 0.17
Nodes (12): Equatable, State, failed, preparing, ready, String, Mode, editing (+4 more)

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
Cohesion: 0.29
Nodes (6): ADR 0005 — Local-first sin autenticación, Consecuencias, Contexto, Decisión, Reconsideración: qué significa "Cerrar sesión", Ver también

### Community 38 - "DSIconButton"
Cohesion: 0.29
Nodes (7): .toolbar, DSIconButton, .body, Bool, CGFloat, String, Void

### Community 41 - "RecordHomeView"
Cohesion: 0.20
Nodes (12): RecordHomeView, .body, .caption, .captionText, .toolbar, Route, more, note (+4 more)

### Community 42 - "DSChip"
Cohesion: 0.33
Nodes (7): DSChip, String, Void, DSTagRow, .body, String, Void

### Community 43 - "NoteEnricher"
Cohesion: 0.36
Nodes (6): NoteEnricher, EnrichTranscript, AsyncThrowingStream, Error, Locale, String

### Community 44 - "NoteError"
Cohesion: 0.22
Nodes (9): NoteError, cancelled, fileNameConflict, indexCorrupted, malformedMarkdown, noteNotFound, noteNotFoundAtPath, permissionDenied (+1 more)

### Community 45 - "VaultPath"
Cohesion: 0.06
Nodes (34): CaseIterable, Codable, Key, NoteMarkdown, Date, Double, Int, String (+26 more)

### Community 46 - "EnrichmentError"
Cohesion: 0.25
Nodes (7): Error, EnrichmentError, cancelled, contextWindowExceeded, guardrailViolation, modelUnavailable, unsupportedLanguage

### Community 47 - "ProfileView"
Cohesion: 0.29
Nodes (8): ProfileView, .body, .vaultDescription, .versionDescription, Int, Int64, String, VaultUsage

### Community 48 - "View"
Cohesion: 0.20
Nodes (10): AttributedString, NoteEditorScreen, .audioSection, .header, .readingBody, String, TimeInterval, ToolbarContent (+2 more)

### Community 49 - "Sendable"
Cohesion: 0.15
Nodes (20): Hashable, Identifiable, Edge, .id, Node, NoteGraph, NoteSearchResult, .id (+12 more)

### Community 50 - "DSCard"
Cohesion: 0.20
Nodes (11): ButtonRole, MoreView, .body, String, Void, DSCard, .body, DSSeparator (+3 more)

### Community 51 - ".callAsFunction"
Cohesion: 0.16
Nodes (12): NoteEnrichment, String, CreateNoteFromRecording, Output, Stage, enriching, installingModel, saved (+4 more)

### Community 52 - "TranscriptionError"
Cohesion: 0.25
Nodes (8): String, TranscriptionError, audioUnreadable, emptyRecording, modelInstallFailed, permissionDenied, unavailableOnDevice, unsupportedLocale

### Community 53 - "Palette"
Cohesion: 0.19
Nodes (11): .taskList, .body, DSAudioLevelMeter, .body, DSProgressBar, .body, Bool, Double (+3 more)

### Community 54 - "Transcriber"
Cohesion: 0.21
Nodes (8): Transcriber, Stage, finished, installing, transcribing, AsyncThrowingStream, Error, TranscribeRecording

### Community 55 - "DSTextField"
Cohesion: 0.19
Nodes (11): Binding, .body, DSTextField, .body, .field, String, Void, .body (+3 more)

### Community 56 - "Capa de datos"
Cohesion: 0.29
Nodes (7): Archivos, Capa de datos, Detalles que no son evidentes, El paquete es iOS-only, Lo que `AudioEngineRecorderTests` no cubre, Tests, Ver también

### Community 57 - "Design System"
Cohesion: 0.29
Nodes (7): Botones que no hacen nada, Capas, Design System, La paleta es `ShapeStyle`, no `Color`, Nombres que evitan colisiones con SwiftUI, Ver también, Verificación

### Community 58 - "Typography"
Cohesion: 0.38
Nodes (4): Font, .editingBody, CGFloat, Typography

### Community 59 - ".text"
Cohesion: 0.33
Nodes (3): AppErrorMessage, Error, String

### Community 60 - "DSRecordingPanel"
Cohesion: 0.43
Nodes (5): .captureScreen, DSRecordingPanel, Double, TimeInterval, Void

### Community 62 - "Presentación"
Cohesion: 0.33
Nodes (6): Archivos, Decisiones que no son evidentes, El flujo de pantallas, Presentación, Tests, Ver también

### Community 63 - "State"
Cohesion: 0.33
Nodes (6): State, failed, idle, processing, recording, String

### Community 64 - "Arquitectura"
Cohesion: 0.40
Nodes (5): ADRs, Arquitectura, Documentos, Modelo de dominio, Paquetes

## Knowledge Gaps
- **269 isolated node(s):** `preparing`, `ready`, `failed`, `.vaultDescription`, `.versionDescription` (+264 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `View` connect `View` to `SwiftUI`, `DSNoteCard`, `AdaptiveColor`, `DSButton`, `DSListScaffold`, `GlassConfig`, `NoteCardModel`, `SplashView`, `NoteEditorViewModel`, `Task`, `DSEmptyState`, `DSIconButton`, `RecordHomeView`, `DSChip`, `ProfileView`, `DSCard`, `Palette`, `DSTextField`, `DSRecordingPanel`?**
  _High betweenness centrality (0.120) - this node is a cross-community bridge._
- **Why does `Note` connect `Note` to `AudioFileRef`, `.save`, `TranscriptSegment`, `FileNoteRepository`, `VaultPath`, `VaultTag`, `View`, `Sendable`, `.callAsFunction`, `NoteCardModel`, `RecordViewModel`, `NoteEditorViewModel`, `Task`?**
  _High betweenness centrality (0.095) - this node is a cross-community bridge._
- **Why does `NoteID` connect `Note` to `.save`, `FileNoteRepository`, `RecordHomeView`, `NoteError`, `VaultPath`, `VaultTag`, `Sendable`, `NoteCardModel`, `NoteEditorViewModel`?**
  _High betweenness centrality (0.074) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `Note` (e.g. with `.addTag()` and `.removeTag()`) actually correct?**
  _`Note` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 12 inferred relationships involving `VaultPath` (e.g. with `.makeNote()` and `.search()`) actually correct?**
  _`VaultPath` has 12 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `VaultTag` (e.g. with `.tagsRow()` and `.inlineTags()`) actually correct?**
  _`VaultTag` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `preparing`, `ready`, `failed` to the rest of the system?**
  _269 weakly-connected nodes found - possible documentation gaps or missing edges._