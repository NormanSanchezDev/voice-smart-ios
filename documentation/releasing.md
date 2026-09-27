---
title: Release y documentación pública
tags: [release, changelog, readme, documentacion, versionado]
created: 2026-09-27
status: actual
---

# Release y documentación pública

Este proyecto tiene tres capas de documentación con audiencias distintas. Confundirlas es
la forma más rápida de que las tres se queden sin actualizar.

| Capa | Dónde | Para quién | Cuándo se actualiza |
| --- | --- | --- | --- |
| **Producto** | `README.md` | Alguien que llega al repo y decide si lo abre | Cuando cambia la superficie pública, el build o las limitaciones |
| **Cambios** | `CHANGELOG.md` | Alguien que ya lo usa y quiere saber qué cambió | En cada release, con lo que entró y lo que se corrigió |
| **Cerebro** | `documentation/` (este Obsidian) | Quien va a mantener el código | De forma continua, con el código, no en la release |

La regla que las separa: el `README` no explica *por qué* el código es como es — para eso
están las notas y los ADR de `documentation/`. Y las notas de `documentation/` no
repeten el `README`, lo enlazan.

## Estado actual: 1.0.0

- `MARKETING_VERSION` 1.0, `CURRENT_PROJECT_VERSION` 1,
  `IPHONEOS_DEPLOYMENT_TARGET` 27.0, `dev.normansanchez.NoteSmart`.
- Rama de release: `release`. Remoto: `voice-smart-ios`
  (`NormanSanchezDev/voice-smart-ios`).
- El `CHANGELOG.md` tiene sección `[No publicado]` vacía. Se llena en el momento del
  corte, no durante el desarrollo.

## Qué tiene que quedar cierto en el `README`

Lo que un `README` profesional no puede equivocarse en:

1. **Cómo se compila y cómo se testea**, con comandos exactos y copiables. Un comando
   que no funciona es peor que ningún comando.
2. **Requisitos reales**, incluidos los incómodos. El `README` dice que hace falta un
   iPhone real y por qué, en vez de dejar que el primer `⌘R` falle — ver
   [[Testing]] para el detalle físico.
3. **Limitaciones conocidas**, escritas sin adornos. El `README` actual lista nueve, y
   todas salen de una nota real de `documentation/`, no de un template:
   - sin tests de UI, y por qué es el hueco que más duele;
   - `NoteSmartUITests` no arranca por firma del runner;
   - el store de simuladores de esta máquina;
   - dos comportamientos sólo verificables en dispositivo;
   - el `.xcworkspace` desactualizado, que todavía referencia `Item.swift` y
     `ContentView.swift`;
   - entitlements heredados de la plantilla;
   - el target de la app en Swift 5 language mode;
   - `Localizable.xcstrings` sin extraer;
   - sin archivo `LICENSE`.
4. **Arquitectura con los números de verdad.** 68 archivos de producción, 6 437 líneas,
   1 921 de test, 110 casos. Los números salen de contar, no de estimar:

   ```bash
   find Packages NoteSmart -name '*.swift' -not -path '*/.build/*' | wc -l
   rg -o '@Test(\([^)]*\))?' Packages NoteSmart -r '' --no-filename | wc -l
   ```

5. **El formato real de una nota**, copiado del códec de
   `NoteSmartData/Sources/NoteSmartData/NoteMarkdown.swift`, no inventado. El transcript
   es JSON compacto con claves ordenadas
   (`confidence`, `end`, `start`, `text`) dentro del frontmatter, entre comillas simples.

## Reglas de escritura

- **El `README` y el `CHANGELOG` están en español**, como el resto de
  `documentation/`. Los nombres de archivos, símbolos y comandos van en inglés, porque no
  se traducen.
- **Nada de capturas inventadas.** La sección de capturas es una tabla con marcadores
  hasta que existan assets en `docs/screenshots/`. Una captura falsa es una mentira
  visual.
- **Nada de badges que no signifiquen algo.** Los del `README` son plataforma, versión de
  Xcode, versión de Swift y licencia. Si la licencia no existe, el badge dice
  `proprietary` y la tabla de limitaciones lo repite.
- **Toda limitación tiene su origen en una nota.** Si la tabla de limitaciones afirma
  algo, tiene que haber una nota en `documentation/` que lo explique, porque si no,
  dentro de seis meses es una afirmación sin respaldo.

## Al preparar la siguiente release

1. `graphify update . --force` — tras un refactor que borre código, el rebuild se niega
   a escribir un graph con menos nodos sin `--force`.
2. Contar líneas y tests de nuevo, y actualizar la tabla de `Paquetes` del `README`.
3. Mover `[No publicado]` a la versión nueva, con fecha, y añadir una `[No publicado]`
   vacía.
4. Releer la sección de **Limitaciones conocidas**: lo que se arregló sale, lo nuevo
   entra. Una lista de limitaciones que nunca se acorta miente sobre el proyecto.
5. Si cambió una decisión, actualizar la nota **y** el ADR. Un ADR que ya no describe el
   código es peor que ningún ADR, porque se cita como autoridad.
6. Anotar en el `CHANGELOG` los bugs corregidos con su síntoma, no con su causa. Al
  guien que pierde una grabación no le importa el `guard` invertido; le importa que la
   primera pulsación no guardaba nada.

## Ver también

- [[Arquitectura]] — el índice del sistema.
- [[Testing]] — de dónde salen los comandos del `README`.
- [[Capa de datos]] — de dónde sale el ejemplo de formato de nota.
- [[Presentación]] — de dónde sale el diagrama de flujo de pantallas.
- [ADR 0005 — Local-first sin autenticación](decisions/0005-local-first-sin-autenticacion.md) —
  por qué el `README` no habla de cuentas.
