---
title: Design System
tags: [diseno, design-system, swiftui, atomic-design, tokens]
created: 2026-09-26
status: actual
---

# Design System

`Packages/NoteSmartDesignSystem`. Atomic Design en cincotargets, sin páginas: las pantallas
se componen en el target de la app. Decisión de material en
[[Liquid Glass sólo en el chrome]].

## Capas

```
DSTokens → DSAtoms → DSMolecules → DSOrganisms → DSTemplates
```

| Target | Contenido |
| --- | --- |
| `DSTokens` | `Palette`, `Spacing`, `Typography`, `Motion`, `Metrics`, `GlassConfig`, `Color+Hex` |
| `DSAtoms` | `DSButton`, `DSIconButton`, `DSChip`/`DSBadge`, `DSCard`, `DSTextField`, `dsGlass` |
| `DSMolecules` | `DSRecordingButton`, `DSAudioLevelMeter`/`DSProgressBar`, `DSEmptyState`/`DSSectionHeader`, `DSTagRow`/`DSFlowLayout` |
| `DSOrganisms` | `DSNoteCard`, `DSRecordingPanel`, `DSSearchResultRow` |
| `DSTemplates` | `DSReadingColumn`, `DSListScaffold`/`DSFloatingToolbar` |

## Nombres que evitan colisiones con SwiftUI

- `Glass.swift` define `GlassConfig`, no `Glass`: iOS 27 ya define `SwiftUI.Glass`.
- `Metrics.swift`, no `Layout.swift`: `SwiftUI.Layout` existe.
- `AdaptiveColor.swift` no importa `CoreGraphics`: `Color(.sRGB, red:green:blue:)`
  ya toma `Double`.

## La paleta es `ShapeStyle`, no `Color`

Cada token es un `AdaptiveColor`, no un `Color`:

```swift
public static let accent = AdaptiveColor(light: 0x5B5BD6, dark: 0x8B8BF0)
```

La razón no es purismo. Un `Color` no puede llevar dos apariaturas: o nombra un
asset o fija una. Antes se resolvía con un provider dinámico de `UIColor`, que
traía dos problemas reales. Uno: `import UIKit` en el package, que es lo único que
el design system no debería necesitar. Dos, más serio: `luminance` leía los canales
con `UIColor(self).getRed(...)`, y sobre un color dinámico eso mide contra
`UITraitCollection.current`, que dentro de SwiftUI no es el environment de la vista.
`readableForeground` sobre una superficie oscura podía estar calculando la variante
clara.

`AdaptiveColor` conforma a `ShapeStyle` con `Resolved = Color.Resolved`, así que
SwiftUI lo resuelve en draw time contra el environment real — el mismo mecanismo que
`HierarchicalShapeStyle`. `Color.Resolved` ya expone canales lineales, de modo que
`luminance` es la fórmula WCAG directa y `luminance(in:)` sobre un token ya mide la
variante correcta. Cero UIKit, cero asset catalog.

El costo es que un `ShapeStyle` no se puede storing, ni interpolar, ni pasar donde
haga falta un `Color`. Hay tres APIs que lo exigen y por eso existe
`resolved(in:)`:

- `Glass.tint(_:)` — por eso `dsGlass` es un `ViewModifier` con `@Environment(\.self)`
  y no un `View` extension que resuelve en el sitio de la llamada.
- `Text.strikethrough(_:color:)`.
- Interpolaciones y gradientes.

Para esas, `@Environment(\.self) private var environment` y
`token.resolved(in: environment)`. `opacity(_:)` existe en el token para no
colapsar a un solo color: `Palette.accentSoft.opacity(0.7)` sigue siendo un token
con las dos apariencias atenuadas.

## Botones que no hacen nada

`DSRecordingPanel` acepta un `onRetry` opcional y sólo dibuja el botón "Reintentar"
cuando quien lo usa lo provee. Antes lo pintaba siempre con una acción vacía: un
botón de reintento que no reintenta es peor que no tenerlo. La app le pasa
`RecordViewModel.dismissFailure`.

## Verificación

El package es iOS 27 y Swift 6, así que `swift build` en el Mac no sirve (UIKit no está
disponible como SDK de destino). El build de referencia es:

```bash
cd Packages/NoteSmartDesignSystem
xcodebuild -scheme NoteSmartDesignSystem-Package \
  -destination 'generic/platform=iOS Simulator' clean build
```

## Ver también

- [[Capa de datos]]
- [[Presentación]]
- [[Arquitectura en capas y reglas de dependencia]]
