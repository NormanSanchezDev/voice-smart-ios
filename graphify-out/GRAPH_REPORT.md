# Graph Report - /Users/normansanchez/AI/jack-projects/voice-smart-notes  (2026-09-26)

## Corpus Check
- cluster-only mode — file stats not available

## Summary
- 46 nodes · 53 edges · 8 communities (6 shown, 2 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 2 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- NoteSmartUITests
- Foundation
- SignInViewModel
- ContentView
- SwiftUI
- NoteSmartApp
- NoteSmartTests.swift
- Item

## God Nodes (most connected - your core abstractions)
1. `SignInViewModel` - 6 edges
2. `NoteSmartUITests` - 6 edges
3. `NoteSmartApp` - 5 edges
4. `SignInUIState` - 5 edges
5. `ContentView` - 4 edges
6. `WelcomeView` - 4 edges
7. `SwiftData` - 3 edges
8. `Item` - 3 edges
9. `.body` - 2 edges
10. `.body` - 2 edges

## Surprising Connections (you probably didn't know these)
- `init()` --references--> `SignInViewModel`  [EXTRACTED]
  NoteSmart/NoteSmart/Presentation/Features/SignIn/SIgnInView.swift → NoteSmart/NoteSmart/Presentation/Features/SignIn/SignInViewModel.swift
- `.body` --calls--> `ContentView`  [INFERRED]
  NoteSmart/NoteSmart/NoteSmartApp.swift → NoteSmart/NoteSmart/ContentView.swift
- `.body` --calls--> `WelcomeView`  [INFERRED]
  NoteSmart/NoteSmart/ContentView.swift → NoteSmart/NoteSmart/Presentation/Features/Welcome/WelcomeView.swift
- `SignInViewModel` --references--> `SignInUIState`  [EXTRACTED]
  NoteSmart/NoteSmart/Presentation/Features/SignIn/SignInViewModel.swift → NoteSmart/NoteSmart/Presentation/Features/SignIn/Model/SignInUIState.swift

## Import Cycles
- None detected.

## Communities (8 total, 2 thin omitted)

### Community 0 - "NoteSmartUITests"
Cohesion: 0.25
Nodes (3): NoteSmartUITests, XCTest, XCTestCase

### Community 1 - "Foundation"
Cohesion: 0.33
Nodes (3): Combine, Foundation, WelcomeViewModel

### Community 2 - "SignInViewModel"
Cohesion: 0.33
Nodes (5): LocalizedStringKey, LocalizedStringResource, SignInUIState, SignInViewModel, ObservableObject

### Community 3 - "ContentView"
Cohesion: 0.33
Nodes (6): ContentView, .body, .body, WelcomeView, .body, View

### Community 4 - "SwiftUI"
Cohesion: 0.40
Nodes (3): init(), SwiftData, SwiftUI

### Community 5 - "NoteSmartApp"
Cohesion: 0.50
Nodes (4): App, ModelContainer, NoteSmartApp, Scene

## Knowledge Gaps
- **4 isolated node(s):** `.body`, `WelcomeViewModel`, `Testing`, `XCTest`
  These have ≤1 connection - possible missing edges or undocumented components.
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SwiftUI` connect `SwiftUI` to `Foundation`, `ContentView`?**
  _High betweenness centrality (0.215) - this node is a cross-community bridge._
- **Why does `SignInUIState` connect `SignInViewModel` to `Foundation`?**
  _High betweenness centrality (0.107) - this node is a cross-community bridge._
- **What connects `.body`, `WelcomeViewModel`, `Testing` to the rest of the system?**
  _4 weakly-connected nodes found - possible documentation gaps or missing edges._