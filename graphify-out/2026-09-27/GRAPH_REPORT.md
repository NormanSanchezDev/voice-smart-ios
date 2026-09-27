# Graph Report - voice-smart-notes  (2026-09-27)

## Corpus Check
- 117 files · ~61,687 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1343 nodes · 3014 edges · 71 communities (67 shown, 4 thin omitted)
- Extraction: 89% EXTRACTED · 11% INFERRED · 0% AMBIGUOUS · INFERRED: 322 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ac646f30`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- NoteSmartUITests
- Foundation
- VaultTag
- EnrichmentProgress
- SwiftUI
- NoteSmart
- .save
- TranscriptSegment
- FileNoteRepository
- Note
- NoteCardModel
- AdaptiveColor
- Añadido
- AudioEngineRecorder
- Handler
- RuleBasedNoteEnricher
- Stage
- Testing
- DSButton
- Hashable
- RTK Commands by Workflow
- .fileName
- DSListScaffold
- GlassConfig
- AppEnvironment
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
- DSFlowLayout
- Sendable
- app.js
- VaultPath
- NoteRepository
- ProfileView
- MarkdownEditingTests
- NoteID
- View
- AudioFileRef
- layout.py
- Palette
- Transcriber
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
- `.body` --calls--> `Task`  [INFERRED]
  NoteSmart/NoteSmart/Presentation/AppRootView.swift → Packages/NoteSmartDomain/Sources/UseCases/MarkdownEditing.swift
- `.body` --calls--> `DSSectionHeader`  [INFERRED]
  NoteSmart/NoteSmart/Presentation/Features/More/MoreView.swift → Packages/NoteSmartDesignSystem/Sources/DSMolecules/DSEmptyState.swift
- `.body` --calls--> `DSListScaffold`  [INFERRED]
  NoteSmart/NoteSmart/Presentation/Features/More/MoreView.swift → Packages/NoteSmartDesignSystem/Sources/DSTemplates/DSListScaffold.swift

## Import Cycles
- None detected.

## Communities (71 total, 4 thin omitted)

### Community 0 - "NoteSmartUITests"
Cohesion: 0.25
Nodes (3): NoteSmartUITests, XCTest, XCTestCase

### Community 1 - "Foundation"
Cohesion: 0.08
Nodes (17): AVFAudio, AVFoundation, DSOrganisms, Foundation, FoundationModels, NoteSmart, AppErrorMessage, NoteBody (+9 more)

### Community 2 - "VaultTag"
Cohesion: 0.14
Nodes (12): Comparable, NoteEnrichmentDraft, OnDeviceNoteEnricher, .availability, AsyncThrowingStream, Error, Locale, String (+4 more)

### Community 3 - "EnrichmentProgress"
Cohesion: 0.17
Nodes (12): EnrichmentProgress, CreateNoteFromRecordingTests, EnrichTranscriptTests, FailingEnricher, InMemoryNoteRepository, StubEnricher, StubTranscriber, AsyncThrowingStream (+4 more)

### Community 4 - "SwiftUI"
Cohesion: 0.21
Nodes (5): DSAtoms, DSMolecules, DSTemplates, DSTokens, SwiftUI

### Community 5 - "NoteSmart"
Cohesion: 0.05
Nodes (41): Antes de abrir un PR, Arquitectura, Búsqueda, Capa de datos, Captura, Captura de audio, Capturas, Cobertura (+33 more)

### Community 6 - ".save"
Cohesion: 0.09
Nodes (27): ModelContext, NoteIndexRecord, .noteID, .tagValues, Bool, Date, Double, Int (+19 more)

### Community 7 - "TranscriptSegment"
Cohesion: 0.08
Nodes (24): .activeSegmentID, OnDeviceTranscriber, AsyncThrowingStream, Bool, Error, Locale, TimeInterval, Bool (+16 more)

### Community 8 - "FileNoteRepository"
Cohesion: 0.12
Nodes (16): DocumentsVaultLocator, FileManager, URL, FileNoteRepository, .rootURL, NoteIndexWriting, FileManager, String (+8 more)

### Community 9 - "Note"
Cohesion: 0.17
Nodes (8): Note, .isEditedByAI, .relativePath, .tags, .title, .transcriptText, Bool, String

### Community 10 - "NoteCardModel"
Cohesion: 0.07
Nodes (34): NoteCardModel, Date, Int, String, TimeInterval, Void, NoteCardModelTests, Bool (+26 more)

### Community 11 - "AdaptiveColor"
Cohesion: 0.11
Nodes (22): EnvironmentValues, DSRecordingButton, .body, .innerDisc, DSRecordingButton.State, .accessibilityHint, .accessibilityLabel, .fillColor (+14 more)

### Community 12 - "Añadido"
Cohesion: 0.10
Nodes (20): [1.0.0] — 2026-09-27, Arquitectura, Audio, Añadido, Añadido — resumen numérico, Build, Changelog, Corregido (+12 more)

### Community 13 - "AudioEngineRecorder"
Cohesion: 0.09
Nodes (21): AsyncStream, AVAudioFile, AVAudioFormat, AVReadOnlyAudioPCMBuffer, AudioEngineRecorder, CaptureSession, .failedWrite, .isCapturing (+13 more)

### Community 14 - "Handler"
Cohesion: 0.07
Nodes (24): BaseHTTPRequestHandler, _get_json(), list_models(), _ping(), Cliente del LLM local (Ollama) para el visor 3D. Responsabilidades: * Detectar…, Generador que rinde el texto de la respuesta a medida que llega. Formato de la…, Estado del LLM. `available=True` solo si el servidor responde Y el modelo…, status() (+16 more)

### Community 15 - "RuleBasedNoteEnricher"
Cohesion: 0.12
Nodes (8): RuleBasedNoteEnricher, .availability, AsyncThrowingStream, Error, Locale, String, String, RuleBasedNoteEnricherTests

### Community 16 - "Stage"
Cohesion: 0.14
Nodes (17): DSRecordingPanel, Stage, done, enriching, failed, .isFailure, .progress, recording (+9 more)

### Community 17 - "Testing"
Cohesion: 0.18
Nodes (11): Bloqueo conocido en esta máquina, Cobertura honesta de la navegación, Compilar sin correr, La ruta que funciona: tests en un iPhone real, `NoteSmartData` es iOS-only, y lo dice, Por qué el dominio corre en el Mac, Qué cubren los tests, Testing (+3 more)

### Community 18 - "DSButton"
Cohesion: 0.14
Nodes (17): ButtonStyle, Configuration, Label, DSButton, .body, DSButtonKind, destructive, glass (+9 more)

### Community 19 - "Hashable"
Cohesion: 0.11
Nodes (19): Hashable, AIAvailability, available, .isAvailable, unavailable, AIUnavailableReason, deviceNotEligible, modelNotReady (+11 more)

### Community 20 - "RTK Commands by Workflow"
Cohesion: 0.13
Nodes (14): Analysis & Debug (70-90% savings), Build & Compile (80-90% savings), Files & Search (60-75% savings), Git (59-80% savings), GitHub (26-87% savings), Golden Rule, Infrastructure (85% savings), JavaScript/TypeScript Tooling (70-90% savings) (+6 more)

### Community 21 - ".fileName"
Cohesion: 0.26
Nodes (4): NoteFileNaming, Bool, String, NoteFileNamingTests

### Community 22 - "DSListScaffold"
Cohesion: 0.16
Nodes (14): AnyView, NoteEditorView, .body, DSFloatingToolbar, .body, DSListScaffold, .body, .floatingBar (+6 more)

### Community 23 - "GlassConfig"
Cohesion: 0.13
Nodes (14): DSGlassModifier, Content, Emphasis, accent, danger, neutral, GlassConfig, .cornerRadius (+6 more)

### Community 24 - "AppEnvironment"
Cohesion: 0.13
Nodes (11): AppEnvironment, ModelContainer, Error, String, AppRootView, .body, String, .list (+3 more)

### Community 25 - "RecordViewModel"
Cohesion: 0.15
Nodes (10): .captureScreen, RecordViewModel, .buttonState, .isBusy, .panel, Bool, Double, Never (+2 more)

### Community 26 - "SplashView"
Cohesion: 0.17
Nodes (10): SplashView, .body, .footer, .mark, .subtitle, .wordmark, String, Void (+2 more)

### Community 27 - "Spacing.swift"
Cohesion: 0.29
Nodes (6): CoreGraphics, Metrics, CGFloat, Radius, Spacing, CGFloat

### Community 28 - "NoteEditorViewModel"
Cohesion: 0.10
Nodes (19): AttributedString, NoteEditorScreen, .audioSection, .header, .readingBody, .taskList, .toolbar, .body (+11 more)

### Community 29 - "AudioPlaybackController"
Cohesion: 0.18
Nodes (10): AVPlayer, AudioPlaybackController, .isLoaded, .progress, Bool, Double, Never, TimeInterval (+2 more)

### Community 31 - "NoteError"
Cohesion: 0.05
Nodes (42): Equatable, Error, State, failed, preparing, ready, String, Mode (+34 more)

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
Cohesion: 0.24
Nodes (10): RecordingsListView, .cards, .emptyState, DSEmptyState, .body, DSSectionHeader, .body, String (+2 more)

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

### Community 42 - "DSFlowLayout"
Cohesion: 0.19
Nodes (13): CGRect, CGSize, Layout, DSFlowLayout, DSTagRow, .body, Row, CGFloat (+5 more)

### Community 43 - "Sendable"
Cohesion: 0.11
Nodes (21): NoteEnricher, AudioAuthorizationStatus, authorized, denied, notDetermined, AudioRecorder, ModelInstallProgress, Bool (+13 more)

### Community 44 - "app.js"
Cohesion: 0.09
Nodes (44): animate(), applyFocus(), boot(), buildBaseEdges(), buildBaseNodes(), buildFocusEdges(), buildFocusNodes(), buildLabels() (+36 more)

### Community 45 - "VaultPath"
Cohesion: 0.08
Nodes (16): Key, NoteMarkdown, Date, Double, Int, String, NoteMarkdownTests, String (+8 more)

### Community 46 - "NoteRepository"
Cohesion: 0.12
Nodes (14): Animation, Duration, Motion, Spring, Bool, Double, DateProvider, FixedDateProvider (+6 more)

### Community 47 - "ProfileView"
Cohesion: 0.29
Nodes (8): ProfileView, .body, .vaultDescription, .versionDescription, Int, Int64, String, VaultUsage

### Community 49 - "NoteID"
Cohesion: 0.13
Nodes (18): CustomStringConvertible, Identifiable, RecordingIndexSpy, .lastIndexed, .lastRemoved, Edge, .id, Node (+10 more)

### Community 50 - "View"
Cohesion: 0.16
Nodes (14): ButtonRole, MoreView, .body, String, Void, String, DSCard, .body (+6 more)

### Community 51 - "AudioFileRef"
Cohesion: 0.12
Nodes (22): CaseIterable, Codable, AudioFileRef, AudioFormat, caf, m4a, AudioRecording, Date (+14 more)

### Community 52 - "layout.py"
Cohesion: 0.26
Nodes (11): _community_colors(), compute(), _fibonacci_sphere(), _fit_radius(), _hsv_to_rgb(), main(), Layout 3D por fuerza dirigida (dos niveles) para el grafo de graphify. Niveles:…, Puntos casi uniformes en una esfera unitaria (rama dorada). (+3 more)

### Community 53 - "Palette"
Cohesion: 0.21
Nodes (10): .body, DSAudioLevelMeter, .body, DSProgressBar, .body, Bool, Double, .outerRing (+2 more)

### Community 54 - "Transcriber"
Cohesion: 0.19
Nodes (9): Transcriber, Stage, finished, installing, transcribing, AsyncThrowingStream, Error, TranscribeRecording (+1 more)

### Community 55 - "DSTextField"
Cohesion: 0.31
Nodes (7): Binding, .body, DSTextField, .body, .field, String, Void

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
Cohesion: 0.30
Nodes (6): MarkdownEditing, Bool, Int, String, Task, Range

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
- **280 isolated node(s):** `preparing`, `ready`, `failed`, `.vaultDescription`, `.versionDescription` (+275 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `View` connect `View` to `RecordingsListView`, `SwiftUI`, `DSIconButton`, `RecordHomeView`, `NoteCardModel`, `AdaptiveColor`, `DSFlowLayout`, `ProfileView`, `Stage`, `DSButton`, `GlassConfig`, `Palette`, `DSListScaffold`, `DSTextField`, `AppEnvironment`, `SplashView`, `NoteEditorViewModel`?**
  _High betweenness centrality (0.099) - this node is a cross-community bridge._
- **Why does `Note` connect `Note` to `VaultTag`, `EnrichmentProgress`, `.save`, `TranscriptSegment`, `FileNoteRepository`, `NoteCardModel`, `Sendable`, `VaultPath`, `NoteRepository`, `NoteID`, `AudioFileRef`, `Hashable`, `AppEnvironment`, `RecordViewModel`, `NoteEditorViewModel`?**
  _High betweenness centrality (0.082) - this node is a cross-community bridge._
- **Why does `VaultTag` connect `VaultTag` to `EnrichmentProgress`, `.save`, `FileNoteRepository`, `Note`, `Sendable`, `VaultPath`, `RuleBasedNoteEnricher`, `MarkdownEditingTests`, `NoteID`, `AudioFileRef`, `Hashable`, `Task`, `NoteEditorViewModel`?**
  _High betweenness centrality (0.063) - this node is a cross-community bridge._
- **Are the 3 inferred relationships involving `Note` (e.g. with `.addTag()` and `.removeTag()`) actually correct?**
  _`Note` has 3 INFERRED edges - model-reasoned connections that need verification._
- **Are the 12 inferred relationships involving `VaultPath` (e.g. with `.makeNote()` and `.search()`) actually correct?**
  _`VaultPath` has 12 INFERRED edges - model-reasoned connections that need verification._
- **Are the 4 inferred relationships involving `VaultTag` (e.g. with `.tagsRow()` and `.inlineTags()`) actually correct?**
  _`VaultTag` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `preparing`, `ready`, `failed` to the rest of the system?**
  _280 weakly-connected nodes found - possible documentation gaps or missing edges._