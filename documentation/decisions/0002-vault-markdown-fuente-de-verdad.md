---
title: El vault markdown es la fuente de verdad
tags: [arquitectura, adr, vault, swiftdata, markdown, obsidian]
created: 2026-09-26
status: aceptada
---

# ADR 0002 — El vault markdown es la fuente de verdad

## Contexto

Una app de notas que guarda todo en su base de datos deja al usuario atrapado: si deja de
usar la app, pierde el acceso. NoteSmart nace para producir un vault que se pueda abrir con
Obsidian, con Finder, o con `cat`.

## Decisión

Los archivos `.md` en `Documents/Vault` son la fuente de verdad. SwiftData es un índice
reconstruible, nunca el almacén.

- `FileNoteRepository` es un `actor`: toda operación es lectura-modificación-escritura sobre
  disco, y dos guardados concurrentes no pueden elegir el mismo nombre libre.
- Cada escritura es atómica. Un crash a mitad de guardado deja la versión anterior intacta,
  no una nota a medio escribir.
- `VaultIndexer` mantiene `NoteIndexRecord` (SwiftData) con título, texto buscable, tags,
  wikilinks y conteo de palabras. Perder la tabla cuesta un rescaneo, nunca datos.
- `synchronize()` se puede llamar en cada arranque: rescanea sólo si el índice está vacío o
  desalineado con el número de archivos. `rebuildIndex()` es el camino de recuperación.

### Frontmatter plano y deliberadamente pequeño

El bloque YAML usa sólo escalares planos, escalares entre comillas, secuencias de flujo
(`[a, b]`) y secuencias de bloque. No se producen mapas anidados ni escalares multilínea,
porque el objetivo es que el bloque sobreviva ida y vuelta por Obsidian y otros editores sin
sorpresas.

El `id` se persiste en el frontmatter para que una nota conserve su identidad entre
lanzamientos. El transcript vive como JSON dentro del frontmatter, fuera del cuerpo: así el
usuario puede reescribir la prosa sin romper la posibilidad de reproducir el audio contra las
palabras.

Las grabaciones de audio van en `Documents/Vault/Recordings`, y esa carpeta se excluye del
enumerado de notas y del listado de carpetas del usuario.

## Consecuencias

- `FileShare` y `UIFileSharingEnabled` tienen sentido: el vault es accesible desde Files.
- La búsqueda es un escaneo en memoria con sabor a BM25 sobre el índice, no FTS5. Un vault
  personal tiene cientos de notas, que escanean en milisegundos, y el esquema se mantiene
  portátil. `VaultIndexer` es la costura donde FTS5 entraría si el vault llega a miles.
- Un `.md` sin frontmatter se salta en el listado en vez de aparecer como nota rota.
- La resolución de wikilinks es insensible a mayúsculas, como en Obsidian.

## Ver también

- [[Capa de datos]]
- [[IA on-device con piso determinista]]
