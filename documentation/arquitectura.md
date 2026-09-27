---
title: Arquitectura
tags: [arquitectura, indice, domain, data, design-system]
created: 2026-09-26
status: actual
---

# Arquitectura

App iOS local-first: graba notas de voz, las transcribe y enriquece en el dispositivo, y las
guarda como Markdown en un vault compatible con Obsidian.

## Paquetes

| Paquete | Contenido | Verificación |
| --- | --- | --- |
| `NoteSmartDomain` | Value objects, entities, protocols, casos de uso. Swift puro, sin UI | `swift test` en el Mac |
| `NoteSmartData` | Vault en disco, índice SwiftData, audio, Speech, FoundationModels | `xcodebuild` sobre simulador |
| `NoteSmartDesignSystem` | Tokens y componentes por capas | `xcodebuild` sobre simulador |
| `NoteSmart` (app) | `DI` + `Presentation`, sin reglas de negocio | `xcodebuild` sobre simulador o dispositivo |

Detalle de reglas de dependencia en
[[Arquitectura en capas y reglas de dependencia]].

## Documentos

- [[Capa de datos]] — códec, repositorio, índice, audio, transcripción, enriquecimiento.
- [[Design System]] — capas, tokens, build de referencia.
- [[Presentación]] — composition root, features, navegación y audio.
- [[Testing]] — cómo correr cada suite y qué depende del simulador.
- [[Release y documentación pública]] — qué vive en el `README`, qué en el `CHANGELOG` y
  qué aquí, y cómo preparar la siguiente versión.

## ADRs

1. [[Arquitectura en capas y reglas de dependencia]]
2. [[El vault markdown es la fuente de verdad]]
3. [[IA on-device con piso determinista]]
4. [[Liquid Glass sólo en el chrome]]
5. [[Local-first sin autenticación]]

## Modelo de dominio

`Note` es la entidad central: `id`, `folder`, `fileName`, `frontmatter`, `body` y
`transcript`. El transcript vive fuera del body para que editar la prosa no rompa la
reproducción del audio. `NoteFrontmatter` es deliberadamente plana —título, fechas, tags,
audio, origen, `enriched`— para que el archivo sobreviva ida y vuelta por Obsidian.

Los casos de uso del pipeline de voz son `TranscribeRecording`, `EnrichTranscript` y
`CreateNoteFromRecording`. Los dos últimos aceptan un enriquecedor que puede fallar: la nota
se guarda igual, sólo que sin toque de IA.
