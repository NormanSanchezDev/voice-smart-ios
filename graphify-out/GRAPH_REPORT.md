# Graph Report - voice-smart-notes  (2026-09-27)

## Corpus Check
- 112 files · ~52,479 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1242 nodes · 2831 edges · 70 communities (66 shown, 4 thin omitted)
- Extraction: 89% EXTRACTED · 11% INFERRED · 0% AMBIGUOUS · INFERRED: 318 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ac646f30`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- NoteSmartUITests
- Foundation
- NoteCardModel
- VaultTag
- SwiftUI
- NoteSmart
- .save
- TranscriptSegment
- VaultPath
- Note
- DSNoteCard
- AdaptiveColor
- Añadido
- AudioEngineRecorder
- View
- RuleBasedNoteEnricher
- NoteFrontmatter
- Testing
- DSButton
- NoteID
- RTK Commands by Workflow
- .fileName
- DSListScaffold
- GlassConfig
- RecordingsListViewModel
- RecordViewModel
- SplashView
- Spacing.swift
- NoteEditorViewModel
- AudioPlaybackController
- NoteError
- ADR 0001 — Arquitectura en capas y reglas de dependencia
- ADR 0002 — El vault markdown es la fuente de verdad
- ADR 0003 — IA on-device con piso determinista
- RecordingsListView
- ADR 0004 — Liquid Glass sólo en el chrome
- ADR 0005 — Local-first sin autenticación
- DSIconButton
- AGENTS.md
- PackageDescription
- RecordHomeView
- DSRecordingButton
- Sendable
- DSRecordingButton.State
- .decode
- Motion
- ProfileView
- MarkdownEditingTests
- Hashable
- DSCard
- AudioFormat
- State
- Palette
- DSTextField
- Capa de datos
- Design System
- Typography
- Task
- Release y documentación pública
- Presentación
- NoteSmartApp
- Arquitectura
- .opencode/AGENTS.md

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

## Communities (70 total, 4 thin omitted)

### Community 0 - "NoteSmartUITests"
Cohesion: 0.25
Nodes (3): NoteSmartUITests, XCTest, XCTestCase

### Community 1 - "Foundation"
Cohesion: 0.07
Nodes (16): AVFAudio, AVFoundation, DSOrganisms, Foundation, FoundationModels, NoteSmart, NoteBody, Bool (+8 more)

### Community 2 - "NoteCardModel"
Cohesion: 0.19
Nodes (9): NoteCardModel, Date, Int, String, TimeInterval, NoteCardModelTests, Bool, String (+1 more)

### Community 3 - "VaultTag"
Cohesion: 0.05
Nodes (46): Comparable, NoteEnrichmentDraft, AsyncThrowingStream, Error, Locale, String, AudioFileRef, Locale (+38 more)

### Community 4 - "SwiftUI"
Cohesion: 0.21
Nodes (5): DSAtoms, DSMolecules, DSTemplates, DSTokens, SwiftUI

### Community 5 - "NoteSmart"
Cohesion: 0.05
Nodes (41): Antes de abrir un PR, Arquitectura, Búsqueda, Capa de datos, Captura, Captura de audio, Capturas, Cobertura (+33 more)

### Community 6 - ".save"
Cohesion: 0.10
Nodes (24): ModelContext, NoteIndexRecord, .tagValues, Bool, Date, Double, Int, String (+16 more)

### Community 7 - "TranscriptSegment"
Cohesion: 0.08
Nodes (22): OnDeviceTranscriber, AsyncThrowingStream, Bool, Error, Locale, Bool, Double, String (+14 more)

### Community 8 - "VaultPath"
Cohesion: 0.09
Nodes (21): DocumentsVaultLocator, FileManager, URL, FileNoteRepository, .rootURL, NoteIndexWriting, FileManager, String (+13 more)

### Community 9 - "Note"
Cohesion: 0.15
Nodes (9): Note, .isEditedByAI, .relativePath, .tags, .title, .transcriptText, Bool, String (+1 more)

### Community 10 - "DSNoteCard"
Cohesion: 0.07
Nodes (37): CGRect, CGSize, Layout, DSBadge, .body, DSChip, String, Void (+29 more)

### Community 11 - "AdaptiveColor"
Cohesion: 0.31
Nodes (6): EnvironmentValues, AdaptiveColor, Color, ShapeStyle, Double, UInt32

### Community 12 - "Añadido"
Cohesion: 0.10
Nodes (20): [1.0.0] — 2026-09-27, Arquitectura, Audio, Añadido, Añadido — resumen numérico, Build, Changelog, Corregido (+12 more)

### Community 13 - "AudioEngineRecorder"
Cohesion: 0.09
Nodes (21): AsyncStream, AVAudioFile, AVAudioFormat, AVReadOnlyAudioPCMBuffer, AudioEngineRecorder, CaptureSession, .failedWrite, .isCapturing (+13 more)

### Community 14 - "View"
Cohesion: 0.20
Nodes (10): AttributedString, NoteEditorScreen, .audioSection, .header, .readingBody, String, TimeInterval, ToolbarContent (+2 more)

### Community 15 - "RuleBasedNoteEnricher"
Cohesion: 0.12
Nodes (8): RuleBasedNoteEnricher, .availability, AsyncThrowingStream, Error, Locale, String, String, RuleBasedNoteEnricherTests

### Community 16 - "NoteFrontmatter"
Cohesion: 0.17
Nodes (10): .activeSegmentID, TimeInterval, NoteFrontmatter, NoteSource, imported, manual, voice, Bool (+2 more)

### Community 17 - "Testing"
Cohesion: 0.18
Nodes (11): Bloqueo conocido en esta máquina, Cobertura honesta de la navegación, Compilar sin correr, La ruta que funciona: tests en un iPhone real, `NoteSmartData` es iOS-only, y lo dice, Por qué el dominio corre en el Mac, Qué cubren los tests, Testing (+3 more)

### Community 18 - "DSButton"
Cohesion: 0.14
Nodes (17): ButtonStyle, Configuration, Label, DSButton, .body, DSButtonKind, destructive, glass (+9 more)

### Community 19 - "NoteID"
Cohesion: 0.19
Nodes (9): CustomStringConvertible, .noteID, RecordingIndexSpy, .lastIndexed, .lastRemoved, NoteID, .description, String (+1 more)

### Community 20 - "RTK Commands by Workflow"
Cohesion: 0.13
Nodes (14): Analysis & Debug (70-90% savings), Build & Compile (80-90% savings), Files & Search (60-75% savings), Git (59-80% savings), GitHub (26-87% savings), Golden Rule, Infrastructure (85% savings), JavaScript/TypeScript Tooling (70-90% savings) (+6 more)

### Community 21 - ".fileName"
Cohesion: 0.26
Nodes (4): NoteFileNaming, Bool, String, NoteFileNamingTests

### Community 22 - "DSListScaffold"
Cohesion: 0.19
Nodes (12): AnyView, DSFloatingToolbar, .body, DSListScaffold, .body, .floatingBar, Bool, Content (+4 more)

### Community 23 - "GlassConfig"
Cohesion: 0.12
Nodes (15): DSGlassModifier, Content, Emphasis, accent, danger, neutral, GlassConfig, .cornerRadius (+7 more)

### Community 24 - "RecordingsListViewModel"
Cohesion: 0.20
Nodes (6): .body, .list, RecordingsListViewModel, .cards, String, Void

### Community 25 - "RecordViewModel"
Cohesion: 0.15
Nodes (10): .captureScreen, RecordViewModel, .buttonState, .isBusy, .panel, Bool, Double, Never (+2 more)

### Community 26 - "SplashView"
Cohesion: 0.13
Nodes (13): Phase, locked, preparing, SplashView, .body, .footer, .mark, .subtitle (+5 more)

### Community 27 - "Spacing.swift"
Cohesion: 0.29
Nodes (6): CoreGraphics, Metrics, CGFloat, Radius, Spacing, CGFloat

### Community 28 - "NoteEditorViewModel"
Cohesion: 0.11
Nodes (15): AppErrorMessage, Error, String, .body, .toolbar, NoteEditorView, .body, NoteEditorViewModel (+7 more)

### Community 29 - "AudioPlaybackController"
Cohesion: 0.18
Nodes (10): AVPlayer, AudioPlaybackController, .isLoaded, .progress, Bool, Double, Never, TimeInterval (+2 more)

### Community 31 - "NoteError"
Cohesion: 0.05
Nodes (45): Equatable, Error, Mode, editing, reading, DSRecordingPanel, Stage, done (+37 more)

### Community 32 - "ADR 0001 — Arquitectura en capas y reglas de dependencia"
Cohesion: 0.29
Nodes (6): ADR 0001 — Arquitectura en capas y reglas de dependencia, Consecuencias, Contexto, Decisión, Reglas de dependencia, Ver también

### Community 33 - "ADR 0002 — El vault markdown es la fuente de verdad"
Cohesion: 0.29
Nodes (6): ADR 0002 — El vault markdown es la fuente de verdad, Consecuencias, Contexto, Decisión, Frontmatter plano y deliberadamente pequeño, Ver también

### Community 34 - "ADR 0003 — IA on-device con piso determinista"
Cohesion: 0.29
Nodes (6): ADR 0003 — IA on-device con piso determinista, Consecuencias, Contexto, Decisión, Reglas del prompt, Ver también

### Community 35 - "RecordingsListView"
Cohesion: 0.20
Nodes (11): RecordingsListView, .cards, .emptyState, String, DSEmptyState, .body, DSSectionHeader, .body (+3 more)

### Community 36 - "ADR 0004 — Liquid Glass sólo en el chrome"
Cohesion: 0.33
Nodes (5): ADR 0004 — Liquid Glass sólo en el chrome, Contexto, Decisión, Por qué `GlassConfig` y no `Glass`, Ver también

### Community 37 - "ADR 0005 — Local-first sin autenticación"
Cohesion: 0.33
Nodes (6): ADR 0005 — Local-first sin autenticación, Consecuencias, Contexto, Decisión, Reconsideración: qué significa "Cerrar sesión", Ver también

### Community 38 - "DSIconButton"
Cohesion: 0.48
Nodes (6): DSIconButton, .body, Bool, CGFloat, String, Void

### Community 41 - "RecordHomeView"
Cohesion: 0.20
Nodes (12): RecordHomeView, .body, .caption, .captionText, .toolbar, Route, more, note (+4 more)

### Community 42 - "DSRecordingButton"
Cohesion: 0.27
Nodes (9): DSRecordingButton, .innerDisc, State, idle, processing, recording, Bool, TimeInterval (+1 more)

### Community 43 - "Sendable"
Cohesion: 0.05
Nodes (51): AppEnvironment, State, failed, preparing, ready, ModelContainer, String, OnDeviceNoteEnricher (+43 more)

### Community 44 - "DSRecordingButton.State"
Cohesion: 0.33
Nodes (7): .body, DSRecordingButton.State, .accessibilityHint, .accessibilityLabel, .fillColor, .isRecording, String

### Community 45 - ".decode"
Cohesion: 0.14
Nodes (10): Key, NoteMarkdown, Date, Double, Int, String, NoteMarkdownTests, String (+2 more)

### Community 46 - "Motion"
Cohesion: 0.25
Nodes (6): Animation, Duration, Motion, Spring, Bool, Double

### Community 47 - "ProfileView"
Cohesion: 0.29
Nodes (8): ProfileView, .body, .vaultDescription, .versionDescription, Int, Int64, String, VaultUsage

### Community 49 - "Hashable"
Cohesion: 0.21
Nodes (12): Hashable, Identifiable, Edge, .id, GraphBuilding, Node, NoteGraph, NoteSearchResult (+4 more)

### Community 50 - "DSCard"
Cohesion: 0.20
Nodes (11): ButtonRole, MoreView, .body, String, Void, DSCard, .body, DSSeparator (+3 more)

### Community 51 - "AudioFormat"
Cohesion: 0.31
Nodes (8): CaseIterable, Codable, AudioFormat, caf, m4a, AudioRecording, Date, String

### Community 52 - "State"
Cohesion: 0.33
Nodes (6): State, failed, idle, processing, recording, String

### Community 53 - "Palette"
Cohesion: 0.21
Nodes (10): .body, DSAudioLevelMeter, .body, DSProgressBar, .body, Bool, Double, .outerRing (+2 more)

### Community 55 - "DSTextField"
Cohesion: 0.43
Nodes (6): Binding, DSTextField, .body, .field, String, Void

### Community 56 - "Capa de datos"
Cohesion: 0.29
Nodes (7): Archivos, Capa de datos, Detalles que no son evidentes, El paquete es iOS-only, Lo que `AudioEngineRecorderTests` no cubre, Tests, Ver también

### Community 57 - "Design System"
Cohesion: 0.29
Nodes (7): Botones que no hacen nada, Capas, Design System, La paleta es `ShapeStyle`, no `Color`, Nombres que evitan colisiones con SwiftUI, Ver también, Verificación

### Community 58 - "Typography"
Cohesion: 0.38
Nodes (4): Font, .editingBody, CGFloat, Typography

### Community 59 - "Task"
Cohesion: 0.33
Nodes (7): AppRootView, .body, String, .taskList, Bool, Int, Task

### Community 60 - "Release y documentación pública"
Cohesion: 0.33
Nodes (6): Al preparar la siguiente release, Estado actual: 1.0.0, Qué tiene que quedar cierto en el `README`, Reglas de escritura, Release y documentación pública, Ver también

### Community 62 - "Presentación"
Cohesion: 0.33
Nodes (6): Archivos, Decisiones que no son evidentes, El flujo de pantallas, Presentación, Tests, Ver también

### Community 63 - "NoteSmartApp"
Cohesion: 0.40
Nodes (4): App, NoteSmartApp, .body, Scene

### Community 64 - "Arquitectura"
Cohesion: 0.40
Nodes (5): ADRs, Arquitectura, Documentos, Modelo de dominio, Paquetes

## Knowledge Gaps
- **276 isolated node(s):** `preparing`, `ready`, `failed`, `.vaultDescription`, `.versionDescription` (+271 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `View` connect `View` to `RecordingsListView`, `SwiftUI`, `DSIconButton`, `RecordHomeView`, `DSNoteCard`, `DSRecordingButton`, `ProfileView`, `DSCard`, `DSButton`, `GlassConfig`, `Palette`, `DSListScaffold`, `DSTextField`, `SplashView`, `Task`, `NoteEditorViewModel`, `NoteError`?**
  _High betweenness centrality (0.112) - this node is a cross-community bridge._
- **Why does `Note` connect `Note` to `NoteCardModel`, `VaultTag`, `.save`, `TranscriptSegment`, `VaultPath`, `Sendable`, `.decode`, `View`, `NoteFrontmatter`, `Hashable`, `NoteID`, `AudioFormat`, `RecordingsListViewModel`, `RecordViewModel`, `NoteEditorViewModel`?**
  _High betweenness centrality (0.092) - this node is a cross-community bridge._
- **Why does `NoteID` connect `NoteID` to `NoteCardModel`, `RecordingsListView`, `VaultTag`, `.save`, `VaultPath`, `RecordHomeView`, `Note`, `Sendable`, `.decode`, `Hashable`, `AudioFormat`, `RecordingsListViewModel`, `NoteEditorViewModel`, `NoteError`?**
  _High betweenness centrality (0.072) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `Note` (e.g. with `.addTag()` and `.removeTag()`) actually correct?**
  _`Note` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 12 inferred relationships involving `VaultPath` (e.g. with `.makeNote()` and `.search()`) actually correct?**
  _`VaultPath` has 12 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `VaultTag` (e.g. with `.tagsRow()` and `.inlineTags()`) actually correct?**
  _`VaultTag` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `preparing`, `ready`, `failed` to the rest of the system?**
  _276 weakly-connected nodes found - possible documentation gaps or missing edges._