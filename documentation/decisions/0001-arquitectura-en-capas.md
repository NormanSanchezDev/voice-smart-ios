---
title: Arquitectura en capas y reglas de dependencia
tags: [arquitectura, adr, domain, data, design-system]
created: 2026-09-26
status: aceptada
---

# ADR 0001 — Arquitectura en capas y reglas de dependencia

## Contexto

NoteSmart es una app iOS local-first: graba audio, lo transcribe en el dispositivo, lo
enriquece con IA on-device y guarda el resultado como Markdown dentro de un vault que el
usuario también puede abrir en Obsidian. El vault es un conjunto de archivos que
overviven a la app, lo que obliga a que la capa de datos sea más importante que la de
presentación.

## Decisión

Tres paquetes Swift Package Manager locales, con dependencias en una sola dirección:

```
NoteSmart (app target)
  ├── Presentation (SwiftUI, Observation, DI)
  ├── DI (composición raíz)
  ├── NoteSmartData ──► NoteSmartDomain
  └── NoteSmartDesignSystem (DSTokens → … → DSTemplates)
```

- `NoteSmartDomain` no importa nada de Apple ni de UI. Es Swift puro: value objects,
  entities, protocols y casos de uso. Es testeable con `swift test` en el Mac.
- `NoteSmartData` implementa los protocols del dominio sobre el sistema de archivos,
  SwiftData, AVFAudio, Speech y FoundationModels.
- La app solo contiene `Presentation` y `DI`. No hay reglas de negocio en las vistas.
- Clean Architecture + MVVM: cada feature tiene un `@Observable` model como state holder.
  Las vistas leen estado e invocan acciones; no orquestan casos de uso.

## Reglas de dependencia

1. `Domain` no importa `Data`, `DesignSystem` ni SwiftUI.
2. `Data` no importa SwiftUI.
3. `Presentation` no importa `FoundationModels`, `Speech` ni `AVFAudio` directamente:
   habla con los protocols del dominio.
4. `Presentation` sólo importa `NoteSmartDomain` de los paquetes de NoteSmart. Ni
   `NoteSmartData` ni `NoteSmartDesignSystem` se filtran hacia abajo más de lo que
   cada archivo necesita para los tipos que nombra. El `composition root` es la
   excepción: `DI/AppEnvironment.swift` sí conoce las implementaciones concretas,
   que es justo lo que existe para hacer.
5. Ningún target importa otro por ruta relativa; sólo por producto SPM.
6. Los nombres de archivos y símbolos van en inglés. El copy de usuario, en español vía
   `Localizable.xcstrings`.
7. UIKit no se usa en ninguna capa. La app es SwiftUI pura: sin `UIView`
   representable, sin app delegate propio, sin `UIColor`. La paleta resuelve sus dos
   apariencias con `ShapeStyle`, no con un provider dinámico de `UIColor`.

## Consecuencias

- El dominio se testea sin simulador ni dispositivo, lo que mantiene el ciclo rápido.
- Los casos de uso se pueden ejercitar con dobles: `NoteEnricher`, `AudioCapturing` y
  `SpeechTranscribing` son protocols precisamente para eso.
- Los ejemplos de UI para componentes del Design System no pueden vivir en `Data`; por eso
  las páginas se componen en la app.
- La regla 4 no es una convención: `AppEnvironment` publica `any NoteRepository`,
  `any NoteSearch`, `any AudioRecorder` y los tipos concretos quedan `private`. Si un
  view model intenta llamar un método que sólo existe en la implementación, no
  compila. Por eso `NoteEditorViewModel`, `NotesListViewModel` y `RecordViewModel` no
  importan `NoteSmartData`.

## Ver también

- [[Vault markdown como fuente de verdad]]
- [[IA on-device con piso determinista]]
