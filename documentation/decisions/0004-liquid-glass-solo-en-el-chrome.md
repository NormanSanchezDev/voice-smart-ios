---
title: Liquid Glass sólo en el chrome
tags: [diseno, adr, liquid-glass, swiftui, design-system]
created: 2026-09-26
status: aceptada
---

# ADR 0004 — Liquid Glass sólo en el chrome

## Contexto

iOS 26/27 introduce Liquid Glass, un material translúcido con refracción. Aplicado a todo,
degrada la legibilidad: el texto de una nota compite con el fondo que se mueve debajo.

## Decisión

El material se usa donde ajuda a la jerarquía y se evita donde estorba:

| Zona | Material |
| --- | --- |
| Tab bar, toolbars, barra de búsqueda, botón de grabación | `GlassConfig` sí |
| Tarjetas de nota, superficie de lectura, listas de resultados | opaco |
| Texto sobre glass | siempre opaco, nunca translúcido |

El token vive en `DSTokens` como `GlassConfig` y se aplica en `DSAtoms` con `dsGlass`. La
superficie de lectura (`DSReadingColumn`) y las tarjetas (`DSCard`) quedan opacas a
propósito.

## Por qué `GlassConfig` y no `Glass`

`SwiftUI` ya define `Glass` en iOS 27. Declarar un `Glass` propio produce ambigüedad de tipo
dentro del Design System. Por eso el token se llama `GlassConfig` y el ViewModifier es
`dsGlass`.

## Ver también

- [[Design System]]
