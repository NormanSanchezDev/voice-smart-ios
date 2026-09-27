<div align="center">

# NoteSmart

**App iOS local-first que graba notas de voz, las transcribe y las enriquece en el
dispositivo, y las guarda como Markdown en un vault compatible con Obsidian.**

Sin cuentas. Sin servidores. Sin una sola petición de red: el audio nunca sale del
dispositivo.

[![iOS 27](https://img.shields.io/badge/iOS-27.0-0A84FF?logo=apple&logoColor=white)](https://developer.apple.com/ios/)
[![Xcode 27](https://img.shields.io/badge/Xcode-27.0-1570F0?logo=xcode&logoColor=white)](https://developer.apple.com/xcode/)
[![Swift 6](https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white)](https://swift.org/)
[![Platform iOS](https://img.shields.io/badge/platform-iOS%20only-lightgrey)]()
[![License](https://img.shields.io/badge/license-proprietary-lightgrey)]()

`SwiftUI` · `Observation` · `SwiftData` · `AVFAudio` · `Speech` · `FoundationModels` · `SwiftPM`

</div>

---

## Tabla de contenidos

- [Qué es](#qué-es)
- [Funcionalidades](#funcionalidades)
- [Capturas](#capturas)
- [Requisitos](#requisitos)
- [Instalación](#instalación)
- [Compilar y ejecutar](#compilar-y-ejecutar)
- [Tests](#tests)
- [Arquitectura](#arquitectura)
  - [Paquetes](#paquetes)
  - [Reglas de dependencia](#reglas-de-dependencia)
  - [Modelo de dominio](#modelo-de-dominio)
  - [Pipeline de voz](#pipeline-de-voz)
  - [Flujo de pantallas](#flujo-de-pantallas)
- [Capa de datos](#capa-de-datos)
  - [El vault es la fuente de verdad](#el-vault-es-la-fuente-de-verdad)
  - [Formato de una nota](#formato-de-una-nota)
  - [Búsqueda](#búsqueda)
  - [Captura de audio](#captura-de-audio)
- [Design System](#design-system)
- [Estructura del proyecto](#estructura-del-proyecto)
- [Decisiones de arquitectura](#decisiones-de-arquitectura)
- [Privacidad](#privacidad)
- [Limitaciones conocidas](#limitaciones-conocidas)
- [Cómo contribuir](#cómo-contribuir)
- [Documentación](#documentación)

---

## Qué es

NoteSmart convierte una idea hablada en un archivo `.md` que sigue siendo legible sin la
app. Pulsas un botón, hablas, y al parar tienes una nota con título, resumen, tags,
action items y un transcript con marcas de tiempo — todo transcrito y resumido **en el
dispositivo**, y todo escrito en `Documents/Vault`, una carpeta de Markdown plano que
puedes abrir con Obsidian, con Finder o con `cat`.

El criterio de diseño que recorre todo el proyecto: **el archivo es la fuente de verdad**.
SwiftData es un índice reconstruible, la IA propone pero nunca bloquea, y ninguna capa
depende de otra en la dirección equivocada.

---

## Funcionalidades

### Captura

- **Un botón y nada más** — la pantalla principal es un único control. El vault vive
  detrás de *Más*, donde su empty state tiene sentido.
- Grabación AAC/M4A con `AVAudioEngine`, con **medidor de nivel en vivo** mientras hablas.
- El `.m4a` se escribe **en streaming a disco**: si la app muere, el audio que ya se
  grabó sigue en el vault.
- Un fallo de escritura se latchea y se reporta — nunca se convierte en un archivo
  silencioso de 0 frames.

### Transcripción

- `SpeechTranscriber` **on-device**, con descarga del modelo visible y cancelable
  (los modelos de voz on-device pesan cientos de MB, así que ocultarlos no es opción).
- Segmentos con `TimeRange` por frase, que después sirven para **resaltar la frase que
  está sonando** y para hacer *seek* tocando el transcript.

### Enriquecimiento

- `FoundationModels` con un `@Generable` `NoteEnrichmentDraft`: título, resumen, tags,
  action items y prosa limpia.
- **Streaming real**: el título aparece en la UI antes de que termine el resto de la
  generación, porque cada `Snapshot` se proyecta a `EnrichmentProgress`.
- **Piso determinista**: `RuleBasedNoteEnricher` deriva título, resumen, tags y tareas
  con heurísticas puras, sin modelo y sin descarga. Si el dispositivo no es elegible,
  Apple Intelligence está apagado, el modelo se está calentando o una llamada salta un
  guardrail, la nota se guarda igual — sólo que sin toque de IA, y con un badge que lo
  dice.
- El prompt incluye reglas explícitas, no sólo una tarea: no inventar, mantener el
  idioma del transcript, y `actionItems` vacío es una respuesta **correcta**.

### Vault

- Notas Markdown con frontmatter plano y deliberadamente pequeño, que sobrevive ida y
  vuelta por Obsidian y otros editores sin sorpresas.
- Escrituras **atómicas**: un crash a mitad de guardado deja la versión anterior intacta,
  nunca una nota a medio escribir.
- Lista de notas ordenadas por `modified`, con tarjetas, carpetas anidadas y navegación
  por `NoteID` (renombrar o mover cambia el path, nunca la identidad).
- Búsqueda con sabor a BM25 sobre un índice reconstruible, con scope por carpeta y por
  tags, snippets, y resolución de wikilinks insensible a mayúsculas.
- Editor con **checklist de tareas extraída del markdown** y audio reproducible con
  resaltado del segmento activo.
- Perfil con uso real del vault (nº de notas, bytes de audio, ubicación) y borrado total
  de datos.

### Local-first de verdad

- Sin autenticación, sin servidor, sin red. *Cerrar sesión* bloquea el vault local hasta
  que lo vuelvas a abrir — que es lo único que ese botón puede significar honestamente.
- `UIFileSharingEnabled`: el vault es accesible desde **Files** sin pasar por la app.
- Desinstalar la app elimina el vault. Está escrito en la pantalla de perfil, sin
  eufemismos.

---

## Capturas

<!--
Coloca las capturas en docs/screenshots/ y sustituye los marcadores de abajo.
El repositorio no tiene todavía ningún asset de imagen.
-->

| Splash | Captura | Editor | Vault |
| --- | --- | --- | --- |
| _pendiente_ | _pendiente_ | _pendiente_ | _pendiente_ |

---

## Requisitos

| | |
| --- | --- |
| **Xcode** | 27.0 (build 27A266a o superior) |
| **SDK / Deployment target** | iOS 27.0 |
| **Swift** | 6.4 tools; los tres paquetes compilan en `swiftLanguageMode(.v6)` |
| **Dispositivo** | iPhone real — el simulador no sirve para el pipeline completo |
| **Apple Intelligence** | Opcional. Sin ella, la app funciona igual vía `RuleBasedNoteEnricher` |
| **Idiomas** | El vault no depende del locale; la transcripción pide el locale del sistema |

> **El target de la app está en `SWIFT_VERSION = 5.0`**, mientras los tres paquetes SPM
> usan Swift 6 language mode. Es intencionado por ahora: migrar el target de la app a
> Swift 6 strict concurrency es trabajo propio, no un cambio de un flag.

### Por qué necesitas un iPhone real

No es una preferencia, es una limitación física:

- El simulador reporta el input del micrófono con **sample rate 0**, así que
  `AudioEngineRecorder.start()` lanza antes de abrir nada.
- `SpeechTranscriber.isAvailable` y `SystemLanguageModel.availability` dan `false` o no
  disponible en simulador, así que el pipeline completo no se puede ejercitar ahí.
- Un `testTarget` de SPM sin host app no puede correr en un dispositivo físico
  (`Tool-hosted testing is unavailable on device destinations`).

---

## Instalación

```bash
git clone https://github.com/NormanSanchezDev/voice-smart-ios.git
cd voice-smart-ios
open voice-smart-notes.xcworkspace
```

Los tres paquetes son **SPM locales por ruta** (`Packages/NoteSmartDomain`,
`NoteSmartData`, `NoteSmartDesignSystem`), no dependencias remotas. No hace falta resolver
nada: `NoteSmartData` ya declara `.package(path: "../NoteSmartDomain")` y el target de la
app referencia los productos por nombre.

No hay `Podfile`, ni `Cartfile`, ni `Package.resolved`. No hay paso de generación de
código.

### Provisioning

El bundle identifier es `dev.normansanchez.NoteSmart`. Para correr en tu propio
dispositivo:

1. En **Signing & Capabilities**, cambia el Team al tuyo.
2. Deja `Automatically manage signing` activado.
3. Los permisos que pide la app, y que Xcode rellena desde el target:
   - `NSMicrophoneUsageDescription` — grabar audio.
   - `NSSpeechRecognitionUsageDescription` — transcribir.
   - `UIBackgroundModes: audio` — poder seguir capturando con la pantalla bloqueada.

> El archivo `NoteSmart.entitlements` que hay en el target arrastra `aps-environment` y
> capacidades de CloudKit **heredadas de la plantilla de SwiftData**. La app no las usa
> (ver [ADR 0005](documentation/decisions/0005-local-first-sin-autenticacion.md)); están
> ahí como deuda a limpiar.

---

## Compilar y ejecutar

```bash
# Abrir el workspace (obligatorio: los paquetes están referenciados desde el proyecto)
open voice-smart-notes.xcworkspace

# Build del paquete del Design System (destino genérico, no necesita simulador booted)
cd Packages/NoteSmartDesignSystem
xcodebuild -scheme NoteSmartDesignSystem-Package \
  -destination 'generic/platform=iOS Simulator' clean build
```

Desde la línea de comandos, contra un simulador o un dispositivo concreto:

```bash
# Listar destinos disponibles (y obtener el UDID de tu iPhone)
xcodebuild -scheme NoteSmart -showdestinations

# Compilar sólo
xcodebuild build -scheme NoteSmart -destination 'id=<UDID>'

# Compilar los tests sin correrlos (atajo útil cuando sólo quieres type-check)
xcodebuild build-for-testing -scheme NoteSmartData \
  -destination 'generic/platform=iOS Simulator'
```

> **`-destination 'platform=macOS'` no es una opción.** `SUPPORTED_PLATFORMS` es
> `"iphoneos iphonesimulator"` con `SDKROOT = iphoneos`, y `NoteSmartData` abre con un
> `#if !os(iOS) #error(…)`. "My Mac" aparece como destino **incompatible** con un
> mensaje, que es exactamente lo que se busca. Antes de ese cambio, compilar el paquete
> para macOS emitía **516 avisos** de availability y luego errores duros, y se leía como
> si faltara algo en cada archivo.

---

## Tests

**110 casos `@Test`** (swift-testing) repartidos en 10 archivos, ~1 900 líneas.

| Suite | Comando | Dónde corre |
| --- | --- | --- |
| `NoteSmartDomain` | `cd Packages/NoteSmartDomain && swift test` | En el Mac, sin simulador |
| `NoteSmartData` | `xcodebuild test -scheme NoteSmart -destination 'id=<UDID>' -only-testing:NoteSmartTests` | En un iPhone real |
| `NoteSmart` (app) | igual que `NoteSmartData` | En un iPhone real |
| `NoteSmartDesignSystem` | `xcodebuild build -scheme NoteSmartDesignSystem-Package -destination 'generic/platform=iOS Simulator'` | Sólo compila |

```bash
# La ruta que funciona: todo en un iPhone real
cd NoteSmart
xcodebuild -scheme NoteSmart -showdestinations          # copiar el UDID
xcodebuild test -scheme NoteSmart \
  -destination 'id=<UDID>' \
  -only-testing:NoteSmartTests
```

Dos cosas que conviene saber sobre ese camino:

- **Sin `-only-testing` falla**, y no por los tests: el target `NoteSmartUITests` no se
  instala (`No se pudo instalar NoteSmartUITests-Runner` — problema de firma del runner).
  `NoteSmartUITests` sigue con el scaffolding de la plantilla de Xcode, así que lo
  razonable es excluirlo hasta que tenga tests que valgan.
- **El contador de XCTest dice `Executed 0 tests` mientras los tests pasan.** Las suites
  usan `swift-testing`, que corre su propio runner. Hay que leer
  `Test case '…' passed` o `✘`, no el resumen de XCTest.

### Cobertura

| Suite | Qué cubre |
| --- | --- |
| `ValueObjectTests` | `NoteID`, `VaultPath`, `VaultTag`, `TimeRange`, `TranscriptSegment` |
| `MarkdownEditingTests` | Toggle de tareas, renombrado, movimiento, conteo de pendientes |
| `UseCaseTests` | Los tres casos de uso del pipeline con fakes de audio/transcripción/enriquecimiento, incluido el camino de fallback sin IA |
| `NoteMarkdownTests` | Ida y vuelta del códec, `id` persistente, títulos con comillas y saltos de línea, frontmatter escrito por otra herramienta, body con wikilinks y code fences, frontmatter ausente o sin cerrar |
| `NoteFileNamingTests` | Diacríticos, separadores repetidos, recorte en frontera de palabra, sufijos numéricos |
| `FileNoteRepositoryTests` | Crear, re-guardar sin duplicar, sufijos por título repetido, renombrarse a sí mismo, carpetas anidadas, `Recordings` excluida, delete y sus errores, move con colisión, y 8 guardados concurrentes del mismo título reclamando nombres distintos |
| `RuleBasedNoteEnricherTests` | Título con fillers, truncado, párrafos, resumen, tags inline y sugeridos, action items en español e inglés, casos vacíos, determinismo |
| `VaultIndexerTests` | Sincronizar, indexar, reindexar, notas borradas, archivos externos, búsqueda multinivel, body opt-in, ranking por título, scope de carpeta y de tags, queries de ruido, snippets, tags del vault, grafo con links colgantes y case-insensitive |
| `AudioEngineRecorderTests` | Parar y cancelar un grabador que nunca arrancó, y que parar dos veces no levante. Ninguno necesita micrófono |
| `NoteSmartTests` | `NoteCardModelTests` (mapeo de tarjeta, preview, fallback al transcript, conteo de tareas pendientes, badge de procedencia) y `NoteBodyTests` (recorte de secciones generadas, `##` del usuario, teaser, cuerpo vacío) |

### Los symlinks de `_DataTests/`

`NoteSmart/NoteSmartTests/_DataTests/` contiene **symlinks** a los seis archivos de
`Packages/NoteSmartData/Tests/NoteSmartDataTests/`. Existen porque `xcodebuild` no puede
correr un `testTarget` de SPM sin host app en un dispositivo, y porque un solo
`xcodebuild test` para todo es más barato que dos.

> **Añadir un archivo de test nuevo a `NoteSmartDataTests` sin añadir su symlink deja el
> test sin ejecutarse nunca.** No es teórico: `AudioEngineRecorderTests` se creó después
> de los symlinks existentes y estuvo semanas sin correr. El fallo de
> `RuleBasedNoteEnricherTests/title()` —un punto final colgando en cada título— apareció
> justo en la primera ejecución real de la suite. Un test que no corre no es un test.

Si editas un test de datos, edítalo en `Packages/NoteSmartData`, no en el symlink.

---

## Arquitectura

Clean Architecture + MVVM, con las fronteras de paquete de SPM **haciendo cumplir** las
reglas de dependencia en el compilador en vez de en la convención.

```
NoteSmart (app target)
  ├── DI          ── composition root: el único sitio que conoce los tipos concretos
  └── Presentation ── SwiftUI + Observation, sin reglas de negocio
        │
        ├──► NoteSmartDesignSystem   (DSTokens → DSAtoms → DSMolecules → DSOrganisms → DSTemplates)
        ├──► NoteSmartDomain         (Swift puro: value objects, entities, protocols, use cases)
        └──► NoteSmartData           ──► NoteSmartDomain
                                          (implementa los protocols sobre disco,
                                           SwiftData, AVFAudio, Speech, FoundationModels)
```

### Paquetes

| Paquete | Archivos | LOC | Contenido | Se verifica con |
| --- | --- | --- | --- | --- |
| `NoteSmartDomain` | 18 | 1 175 | Value objects, entities, protocols, casos de uso. Sin UI, sin frameworks de Apple más allá de Foundation | `swift test` en el Mac |
| `NoteSmartData` | 11 | 1 729 | Vault en disco, índice SwiftData, audio, Speech, FoundationModels | `xcodebuild` en dispositivo |
| `NoteSmartDesignSystem` | 22 | 1 357 | Tokens y componentes por capas de Atomic Design | `xcodebuild` contra el SDK de iOS |
| `NoteSmart` (app) | 17 | 2 176 | `DI` + `Presentation`, sin reglas de negocio | `xcodebuild` en dispositivo o simulador |
| Tests | 10 | 1 921 | 110 casos swift-testing | ver [Tests](#tests) |

### Reglas de dependencia

1. `Domain` no importa `Data`, `DesignSystem` ni SwiftUI.
2. `Data` no importa SwiftUI.
3. `Presentation` no importa `FoundationModels`, `Speech` ni `AVFAudio` directamente:
   habla con los protocols del dominio.
4. `Presentation` sólo importa `NoteSmartDomain` de los paquetes de NoteSmart. El
   *composition root* es la excepción: `DI/AppEnvironment.swift` sí conoce las
   implementaciones concretas — que es justo lo que existe para hacer.
5. Ningún target importa otro por ruta relativa; sólo por producto SPM.
6. Los nombres de archivos y símbolos van en inglés. El copy de usuario, en español vía
   `Localizable.xcstrings`.
7. UIKit no se usa en ninguna capa. La app es SwiftUI pura: sin `UIView` representable,
   sin app delegate propio, sin `UIColor`.

**La regla 4 la garantiza el compilador.** `AppEnvironment` publica `any NoteRepository`,
`any NoteSearch`, `any AudioRecorder`, `any Transcriber`; los pares concretos
(`FileNoteRepository`, `VaultIndexer`) quedan `private` para poder enlazar el ciclo. Si un
view model intenta llamar un método que sólo existe en la implementación, no compila.
Por eso `RecordViewModel`, `RecordingsListViewModel` y `NoteEditorViewModel` **no importan
`NoteSmartData`** — una consecuencia que se comprueba mecánicamente, no una promesa.

Hay exactamente **un ciclo** en el graph: `FileNoteRepository` refresca el índice en cada
escritura y `VaultIndexer` necesita el repositorio para rescannear. Ninguno se puede
construir primero con el otro en la mano, así que `AppEnvironment` construye ambos y los
enlaza con `attachIndex` una vez, antes de leer o escribir nada.

### Modelo de dominio

`Note` es la entidad central: `id`, `folder`, `fileName`, `frontmatter`, `body` y
`transcript`.

- El **transcript vive fuera del body** para que editar la prosa nunca rompa la
  reproducción del audio contra las palabras.
- `NoteFrontmatter` es deliberadamente plana —título, fechas, tags, audio, origen,
  `enriched`— para que el archivo sobreviva ida y vuelta por Obsidian.
- `NoteID` es identidad persistente, no ruta: renombrar o mover no rompe la navegación.

Value objects: `NoteID`, `VaultPath`, `VaultTag` (`Comparable`, `#tag` display),
`TimeRange`, `TranscriptSegment`.

Protocols: `NoteRepository`, `NoteSearch`, `NoteEnricher`, `AudioRecorder`, `Transcriber`,
`VaultLocator`, `DateProvider`. Los últimos dos existen para que la app se pueda testear
con dobles, y para que la ubicación del vault pueda moverse a iCloud más adelante sin
tocar un solo call site.

### Pipeline de voz

`CreateNoteFromRecording` es el caso de uso que coordina todo, y emite su progreso como
un `AsyncThrowingStream<Stage, Error>`:

```
.start()  ──►  .installingModel(progress)  ──►  .transcribing(progress)  ──►  .enriching(progress)  ──►  .saved(note)
   │                                                │                            │
   └─ El audio ya está en disco                    └─ Si falla, la nota          └─ Si falla, cae a
      antes de transcribir                             se guarda igual               RuleBased
```

`EnrichTranscript` y `CreateNoteFromRecording` aceptan un enriquecedor que **puede
fallar**: la nota se guarda de todos modos, sólo que sin toque de IA. `TranscribeRecording`
está separado del caso de uso grande para poder transcribir sin escribir, y para que la
descarga del modelo sea un paso testeable por su cuenta.

### Flujo de pantallas

```
NoteSmartApp
└── AppRootView                    dueña del environment y del bootstrap
    ├── SplashView(.preparing)     mientras se abre y sincroniza el vault (mín. 450 ms)
    ├── DSEmptyState(.failed)      si el vault no se puede abrir
    └── RootView                   enruta por environment.state
        ├── SplashView(.locked)    vault cerrado → botón "Abrir vault"
        └── RecordHomeView         un botón de grabación + acceso a "Más"
            ├── "Más" (arriba derecha) → MoreView
            │   ├── Grabaciones previas → RecordingsListView → NoteEditorView
            │   ├── Perfil               → ProfileView
            │   └── Cerrar sesión       → environment.lock() → SplashView(.locked)
            └── al guardar → NoteEditorView
```

El `NavigationStack` vive en `RecordHomeView`, no en la lista: un `NavigationStack`
anidado por pantalla que se empuja desde un toolbar se rompe al hacer pop, porque el
título y el botón de atrás pertenecen a la pila interior. La ruta es un enum
(`RecordHomeView.Route`), así que un destino no puede empujarse en la pila equivocada y
el `switch` del compilador cubre el flujo entero.

Los view models (`@MainActor @Observable`) se crean en `.task(id: environment.state)`:
`@Environment` no existe en `init`, así que crearlos en la propiedad `@State` los dejaría
sin dependencias.

---

## Capa de datos

| Archivo | Responsabilidad |
| --- | --- |
| `DocumentsVaultLocator.swift` | Localiza `Documents/Vault` y `Vault/Recordings` detrás de `VaultLocator` |
| `NoteMarkdown.swift` | Códec del archivo: frontmatter plano, transcript JSON, quoting y parsing |
| `NoteFileNaming.swift` | Slug ASCII, recorte en frontera de palabra, desambiguación con sufijo numérico |
| `FileNoteRepository.swift` | `actor` del vault: lectura recursiva, escrituras atómicas, move, delete, indexado |
| `NoteIndexRecord.swift` | Proyección SwiftData de cada nota, reconstruible |
| `VaultIndexer.swift` | Búsqueda con sabor a BM25, tags y grafo de wikilinks |
| `AudioEngineRecorder.swift` | Grabación AAC/M4A con `AVAudioEngine`, meter en vivo, pause/resume |
| `OnDeviceTranscriber.swift` | `SpeechTranscriber` con `AssetInventory`, segmentos y tiempos |
| `OnDeviceNoteEnricher.swift` | `FoundationModels` con `@Generable` y streaming de progreso |
| `RuleBasedNoteEnricher.swift` | Piso determinista, sin modelo |
| `Platform.swift` | `#if !os(iOS) #error(…)` — este package no es para macOS |

### El vault es la fuente de verdad

Una app que guarda todo en su base de datos deja al usuario atrapado: si deja de usar la
app, pierde el acceso. Los `.md` en `Documents/Vault` son la fuente de verdad; SwiftData
es un índice reconstruible, nunca el almacén.

- `FileNoteRepository` es un `actor`: toda operación es lectura-modificación-escritura sobre
  disco, así que dos guardados concurrentes no pueden elegir el mismo nombre libre.
- Cada escritura es atómica. Un crash a mitad de guardado deja la versión anterior intacta.
- `VaultIndexer.synchronize()` se puede llamar en cada arranque: rescanea sólo si el
  índice está vacío o desalineado con el número de archivos. `rebuildIndex()` es el camino
  de recuperación, y perder la tabla cuesta un rescaneo, nunca datos.
- El índice **no se adjunta a la scene**. Es un detalle de implementación de la búsqueda:
  la lista lee el repositorio, no SwiftData. Si `Presentation` no importa SwiftData, nadie
  puede engancharle un `@Query` por descuido.
- `VaultIndexer` construye su **propio `ModelContext`** a partir del `ModelContainer`.
  `ModelContext` no es `Sendable`, así que un indexer que tomara prestado el `mainContext`
  sería una carrera de datos esperando a ocurrir. Construirlo dentro del actor además le
  da su propia cola, que es lo que mantiene fluida la escritura en el campo de búsqueda.

### Formato de una nota

```markdown
---
id: 3F2A1B4C-8E5D-4A7B-9C1D-2E6F8A0B3C5D
title: "Plan para el trimestre"
created: 2026-09-27T14:32:08Z
modified: 2026-09-27T14:33:41Z
tags: [plan, trabajo, q4]
source: voice
enriched: true
audio: "3F2A1B4C-8E5D-4A7B-9C1D-2E6F8A0B3C5D.m4a"
audio_duration: 47.28
transcript: '[{"confidence":0.94,"end":2.4,"start":0.0,"text":"Hay que cerrar el roadmap antes del viernes."}]'
---

Hay que cerrar el roadmap antes del viernes. Elena se encarga de la parte de
clientes y yo me quedo con la de infra.

## Action items

- [ ] Cerrar el roadmap antes del viernes
- [ ] Elena: parte de clientes

## Transcript

Hay que cerrar el roadmap antes del viernes…
```

El códec sólo produce un subconjunto plano de YAML —escalares simples, escalares entre
comillas, secuencias de flujo `[a, b]` y secuencias de bloque—. No se producen mapas
anidados ni escalares multilínea, porque el objetivo es que el bloque sobreviva ida y
vuelta por Obsidian y otros editores sin sorpresas. Los mapas anidados y los
multilínea que se encuentren al leer se saltan en vez de romper el parseo.

El `id` se persiste en el frontmatter para que una nota conserve su identidad entre
lanzamientos. El **transcript va en el frontmatter, no en el cuerpo**, que es lo que
permite reescribir la prosa sin romper la reproducción del audio contra las palabras.

`## Action items` y `## Transcript` los escribe la app y el editor los renderiza como
checklist y timeline, así que `NoteBody` los recorta del markdown. Sin ese recorte cada
action item aparecería dos veces: como texto `- [ ]` y como control que funciona. Un `##`
escrito por el usuario **no** se recorta en el editor — sólo en el teaser de la tarjeta.

Las grabaciones van en `Documents/Vault/Recordings`, y esa carpeta se excluye del
enumerado de notas y del listado de carpetas: los recordings no son notas.

### Búsqueda

`VaultIndexer` es un escaneo en memoria con sabor a BM25 sobre el índice — no FTS5. Un
vault personal tiene cientos de notas, que escanean en milisegundos, y el esquema se
mantiene portátil. `VaultIndexer` es exactamente la costura donde entraría FTS5 si el
vault llega a miles de notas.

- Ranking con título por encima del cuerpo; `includeBody` es opt-in.
- `SearchScope` filtra por carpeta y por tags.
- Resolución de wikilinks insensible a mayúsculas, como en Obsidian; los links
  colgantes se guardan y no rompen nada.
- Un `.md` sin frontmatter utilizable se salta en el listado en vez de aparecer como nota
  rota.

### Captura de audio

Cuatro decisiones que no son evidentes y cuestan un `.m4a` de 0 frames si se ignoran:

- **Un solo formato para toda la captura.** `start()` construye un `AVAudioFormat` float32
  no entrelazado a partir del formato del hardware y usa *ese* tanto para
  `installAudioTap` como para `makeFile`. `AVAudioEngine` convierte del hardware a ese
  formato, y como el `.m4a` se construye con la misma disposición, el `processingFormat`
  del fichero y el del tap son idénticos y `file.write(from:)` no puede fallar por un
  desajuste de canales. La versión anterior forzaba mono con
  `min(format.channelCount, 1)` mientras el tap entregaba estéreo, y **cada `write`
  lanzaba**.
- **La sesión de captura tiene su propio `NSLock`.** El tap de audio llega en la cola de
  render en tiempo real, no en el actor: sin el lock, escribir el buffer y leer
  `isCapturing` desde dos hilos es una carrera.
- **Un error de escritura se latchea, no se traga.** `consume()` guardaba el resultado con
  `try?`: un buffer descartado es indistinguible del silencio para el usuario. Ahora el
  primer error queda en `writeError`, y `stop()` lo reporta y borra el fichero.
- **La duración sale del fichero, no del reloj.** `finish()` devuelve `frameCount`, y
  `stop()` tira el `.m4a` y lanza `emptyRecording` si es 0. Antes la duración caía al
  reloj de pared, así que una captura que no capturó nada devolvía una duración plausible
  y la UI la aceptaba.

También: el tap de audio usa la API nueva de iOS 27
(`installAudioTap(onBus:bufferSize:format:tapProvider:)` lanza en vez de devolver `Void` y
entrega `AVReadOnlyAudioPCMBuffer`), y el RMS itera por índice porque `Span<Float>` no
expone `prefix(_:)`.

---

## Design System

`Packages/NoteSmartDesignSystem`. Atomic Design en cinco targets, **sin páginas**: las
pantallas se componen en el target de la app, porque las páginas llevan datos reales.

```
DSTokens → DSAtoms → DSMolecules → DSOrganisms → DSTemplates
```

Las dependencias sólo fluyen hacia arriba, y los límites entre targets **son** la
arquitectura: no se puede importar un organismo desde un átomo porque SPM no lo permite.

| Target | Contenido |
| --- | --- |
| `DSTokens` | `Palette`, `Spacing`, `Typography`, `Motion`, `Metrics`, `GlassConfig`, `AdaptiveColor`, `Color+Hex` |
| `DSAtoms` | `DSButton`, `DSIconButton`, `DSChip`/`DSBadge`, `DSCard`, `DSTextField`, `dsGlass` |
| `DSMolecules` | `DSRecordingButton`, `DSAudioLevelMeter`/`DSProgressBar`, `DSEmptyState`/`DSSectionHeader`, `DSTagRow`/`DSFlowLayout` |
| `DSOrganisms` | `DSNoteCard`, `DSRecordingPanel`, `DSSearchResultRow` |
| `DSTemplates` | `DSReadingColumn`, `DSListScaffold`/`DSFloatingToolbar` |

### La paleta es `ShapeStyle`, no `Color`

Cada token de color es un `AdaptiveColor`, no un `Color`:

```swift
public static let accent = AdaptiveColor(light: 0x5B5BD6, dark: 0x8B8BF0)
```

Un `Color` no puede llevar dos apariencias: o nombra un asset o fija una. La solución
anterior era un provider dinámico de `UIColor`, y traía dos problemas reales. Uno:
`import UIKit` en el package, que es lo único que el design system no debería necesitar.
Dos, más serio: `luminance` leía los canales con `UIColor(self).getRed(...)`, y sobre un
color dinámico eso mide contra `UITraitCollection.current`, que **dentro de SwiftUI no es
el environment de la vista** — `readableForeground` sobre una superficie oscura podía
estar calculando la variante clara.

`AdaptiveColor` conforma a `ShapeStyle` con `Resolved = Color.Resolved`, así que SwiftUI
lo resuelve en draw time contra el environment real — el mismo mecanismo que
`HierarchicalShapeStyle`. `Color.Resolved` ya expone canales lineales, de modo que
`luminance` es la fórmula WCAG directa. Cero UIKit, cero asset catalog.

El costo es que un `ShapeStyle` no se puede storing, ni interpolar, ni pasar donde haga
falta un `Color`. Hay tres APIs que lo exigen y por eso existe `resolved(in:)`:
`Glass.tint(_:)` (que es la razón de que `dsGlass` sea un `ViewModifier` con
`@Environment(\.self)` y no una extensión de `View`), `Text.strikethrough(_:color:)` e
interpolaciones y gradientes. Para ésas: `token.resolved(in: environment)`.
`opacity(_:)` existe en el token para no colapsar a un solo color —
`Palette.accentSoft.opacity(0.7)` sigue siendo un token con las dos apariencias atenuadas.

### Liquid Glass sólo en el chrome

Aplicado a todo, el material translúcido degrada la legibilidad: el texto de una nota
compite con el fondo que se mueve debajo.

| Zona | Material |
| --- | --- |
| Tab bar, toolbars, barra de búsqueda, botón de grabación | `GlassConfig` sí |
| Tarjetas de nota, superficie de lectura, listas de resultados | opaco |
| Texto sobre glass | siempre opaco, nunca translúcido |

El token se llama `GlassConfig` y no `Glass` porque **SwiftUI ya define `Glass` en iOS
27**; declarar un `Glass` propio produce ambigüedad de tipo dentro del design system. Por
eso el `ViewModifier` es `dsGlass` y no `glass`. Por lo mismo `Metrics.swift` y no
`Layout.swift` (`SwiftUI.Layout` existe).

### Nombres que evitan colisiones, y botones que sí hacen algo

- `DSRecordingPanel` acepta un `onRetry` **opcional** y sólo dibuja el botón
  "Reintentar" cuando quien lo usa lo provee. Antes lo pintaba siempre con una acción
  vacía: un botón de reintento que no reintenta es peor que no tenerlo. La app le pasa
  `RecordViewModel.dismissFailure`.
- No hay pause/resume en la UI aunque el protocol los tenga. `DSRecordingButton` es un
  control de dos estados —grabar y parar— y un tercer estado sin diseño sería un botón sin
  forma. Cuando se quiera, se añade el estado al design system primero.

---

## Estructura del proyecto

```
voice-smart-ios/
├── voice-smart-notes.xcworkspace     # abrir siempre esto, no el .xcodeproj
│
├── NoteSmart/                        # ── App target ──
│   ├── NoteSmart.xcodeproj
│   ├── NoteSmart/
│   │   ├── NoteSmartApp.swift        # @main
│   │   ├── DI/
│   │   │   ├── AppEnvironment.swift  # composition root
│   │   │   └── AppErrorMessage.swift # los 3 enums de error → texto mostrable
│   │   ├── Presentation/
│   │   │   ├── AppRootView.swift     # dueña del environment y del bootstrap
│   │   │   ├── RootView.swift        # ruta por estado del graph
│   │   │   ├── Features/
│   │   │   │   ├── Splash/           # SplashView
│   │   │   │   ├── Record/           # RecordHomeView, RecordViewModel
│   │   │   │   ├── More/             # MoreView, ProfileView
│   │   │   │   ├── Recordings/       # RecordingsListView(+ViewModel)
│   │   │   │   └── NoteEditor/       # NoteEditorView(+ViewModel), AudioPlaybackController
│   │   │   └── Support/              # NoteCardModel, NoteBody
│   │   ├── Assets.xcassets/
│   │   ├── Info.plist                # UIBackgroundModes: audio, UIFileSharingEnabled
│   │   ├── Localizable.xcstrings     # 26 cadenas
│   │   └── NoteSmart.entitlements
│   ├── NoteSmartTests/
│   │   ├── NoteSmartTests.swift      # presentación (funciones puras)
│   │   └── _DataTests/               # symlinks a NoteSmartDataTests
│   └── NoteSmartUITests/             # scaffolding, sin tests
│
├── Packages/                         # ── SPM local, sin dependencias remotas ──
│   ├── NoteSmartDomain/
│   │   ├── Sources/
│   │   │   ├── ValueObjects/         # NoteID, VaultPath, TimeRange
│   │   │   ├── Entities/             # Note, NoteFrontmatter, TranscriptSegment,
│   │   │   │                         #   VaultTag, AudioRecording
│   │   │   ├── Protocols/            # NoteRepository, NoteSearch, NoteEnricher,
│   │   │   │                         #   AudioRecorder, Transcriber, VaultLocator,
│   │   │   │                         #   DateProvider
│   │   │   ├── UseCases/             # CreateNoteFromRecording, TranscribeRecording,
│   │   │   │                         #   EnrichTranscript, MarkdownEditing
│   │   │   └── Errors/
│   │   └── Tests/NoteSmartDomainTests/
│   ├── NoteSmartData/
│   │   ├── Sources/NoteSmartData/    # 11 archivos, ver "Capa de datos"
│   │   └── Tests/NoteSmartDataTests/ # 6 archivos
│   └── NoteSmartDesignSystem/
│       ├── Sources/                  # DSTokens, DSAtoms, DSMolecules,
│       │                             #   DSOrganisms, DSTemplates
│       └── Package.swift             # 5 targets, 5 productos
│
├── documentation/                    # cerebro del proyecto (Obsidian)
│   ├── arquitectura.md
│   ├── capa-de-datos.md
│   ├── design-system.md
│   ├── presentacion.md
│   ├── testing.md
│   ├── releasing.md
│   └── decisions/                    # ADR 0001 – 0005
│
├── graphify-out/                     # grafo de conocimiento del repo
│   ├── GRAPH_REPORT.md
│   └── graph.html
│
├── AGENTS.md                         # reglas para el agente
├── CLAUDE.md                         # reglas de RTK
├── CHANGELOG.md
└── README.md
```

---

## Decisiones de arquitectura

Cada decisión tiene su ADR con contexto, decisión, consecuencias y "ver también". Están
en `documentation/decisions/` y forman un grafo de Obsidian con `[[wikilinks]]`.

| ADR | Decisión | Consecuencia principal |
| --- | --- | --- |
| [0001](documentation/decisions/0001-arquitectura-en-capas.md) | Arquitectura en capas y reglas de dependencia | El dominio se testea sin simulador; la regla 4 la hace cumplir el compilador, no la convención |
| [0002](documentation/decisions/0002-vault-markdown-fuente-de-verdad.md) | El vault markdown es la fuente de verdad | Perder la app no pierde las notas; perder el índice cuesta un rescaneo. Frontmatter plano y pequeño |
| [0003](documentation/decisions/0003-ia-on-device-con-piso-determinista.md) | IA on-device con piso determinista | El modelo propone, nunca bloquea. La app funciona en un iPad viejo, en un simulador y sin Apple Intelligence |
| [0004](documentation/decisions/0004-liquid-glass-solo-en-el-chrome.md) | Liquid Glass sólo en el chrome | El material va donde ayuda a la jerarquía; el texto nunca va sobre translúcido |
| [0005](documentation/decisions/0005-local-first-sin-autenticacion.md) | Local-first sin autenticación | Se elimina el scaffolding de la plantilla. "Cerrar sesión" bloquea el vault local, y el perfil dice en voz alta que nada sale del dispositivo |

---

## Privacidad

- **No hay red.** Ninguna nota, grabación o transcripción sale del dispositivo. No hay
  backend, no hay analytics, no hay telemetría.
- **No hay cuentas.** Ni registro, ni email, ni "inicio de sesión con Apple". El modelo de
  `FoundationModels` corre en el dispositivo y el de Speech también.
- **El vault es tuyo.** Vive en `Documents/Vault`, visible desde Files, y se puede abrir
  con cualquier editor. Nada de formato propietario.
- **Desinstalar elimina los datos.** Sin copia en ningún otro sitio, y sin copy que lo
  disimule: está escrito en la pantalla de perfil.
- **Permisos mínimos.** Micrófono y reconocimiento de voz, y sólo cuando el usuario
  toca grabar.
- **"Cerrar sesión" bloquea, no borra.** Bloquea el vault local hasta que se vuelva a
  pedir. No hay sesión remota que cerrar.

---

## Limitaciones conocidas

Documentadas con honestidad, porque una lista de limitaciones que miente es peor que no
tenerla.

| Limitación | Detalle |
| --- | --- |
| **Sin tests de UI** | El flujo de pantallas —splash, el botón, *Más*, grabaciones, perfil, cerrar sesión— **no tiene tests**. Es el hueco más grande de la suite. El bug del `guard` invertido de `start()` llegó a producción precisamente porque nada ejercitaba la ruta del botón |
| **`NoteSmartUITests` no arranca** | `No se pudo instalar NoteSmartUITests-Runner`. Es un problema de firma del runner, no del simulador. El target sigue con el scaffolding de la plantilla de Xcode, así que las rutas de `xcodebuild test` necesitan `-only-testing:NoteSmartTests` |
| **Store de simuladores roto en esta máquina** | `~/Library/Developer/CoreSimulator` es un symlink a `/Volumes/MacSSD/...` y `CoreSimulatorService` recibe `EPERM` al escribir. No bloquea los tests (corren en un iPhone real), pero sí la iteración rápida de UI |
| **Dos comportamientos sólo verificables en dispositivo** | Que el `.m4a` tenga frames, y que la segunda captura muestre onda y cronómetro. El simulador reporta input con sample rate 0, así que un test escrito ahí sería un test que no puede fallar |
| **El workspace está desactualizado** | `voice-smart-notes.xcworkspace/contents.xcworkspacedata` todavía referencia `Item.swift` y `ContentView.swift`, que se eliminaron al quitar el scaffolding de la plantilla. No afecta al build vía el `.xcodeproj`, pero conviene regenerarlo |
| **Entitlements heredados** | `NoteSmart.entitlements` arrastra `aps-environment` y CloudKit de la plantilla de SwiftData. No se usan |
| **Target de la app en Swift 5** | `SWIFT_VERSION = 5.0` mientras los paquetes usan Swift 6 language mode. Migrar el target a Swift 6 strict concurrency es trabajo propio |
| **Localizable sin extraer** | 26 cadenas con el copy en español y `sourceLanguage: en`. El catálogo tiene las claves en estado `new`, sin localización por separado |
| **Sin `LICENSE`** | El repositorio no declara licencia. Todos los derechos reservados por defecto |

---

## Cómo contribuir

### Reglas que no se negocian

1. **La dirección de las dependencias manda.** Antes de añadir un `import`, comprueba
   contra [ADR 0001](documentation/decisions/0001-arquitectura-en-capas.md). Si
   `Presentation` necesita un método que sólo existe en la implementación, el problema es
   el protocol, no el `import`.
2. **El markdown sigue siendo la fuente de verdad.** Nada de estado que sólo viva en
   SwiftData. Si se pierde el índice, tiene que poder reconstruirse.
3. **La IA propone, nunca bloquea.** Un camino de fallo que no termina en un error
   visible es un bug, aunque el modelo no falle nunca.
4. **UIKit no.** Ni en la app, ni en los paquetes. La paleta resuelve sus dos apariencias
   con `ShapeStyle`.
5. **Nombres y símbolos en inglés; copy de usuario en español** vía
   `Localizable.xcstrings`.
6. **Un comentario explica el porqué, no el qué.** El código de este repo sigue esa
   convención: los comentarios de más valor son los que explican una decisión que parece
   arbitraria, y casi todos tienen la forma *«por qué no lo obvio»*.

### Antes de abrir un PR

```bash
# 1. El dominio, que es rápido y no necesita dispositivo
cd Packages/NoteSmartDomain && swift test

# 2. El design system contra el SDK de iOS
cd Packages/NoteSmartDesignSystem && xcodebuild build \
  -scheme NoteSmartDesignSystem-Package \
  -destination 'generic/platform=iOS Simulator'

# 3. Todo lo demás, en un iPhone real
cd NoteSmart && xcodebuild test -scheme NoteSmart \
  -destination 'id=<UDID>' -only-testing:NoteSmartTests
```

- **Añadir un test nuevo a `NoteSmartDataTests` implica añadir su symlink** en
  `NoteSmart/NoteSmartTests/_DataTests/`.
- **El graph del repo está en `graphify-out/`.** Después de un refactor que borre código,
  `graphify update . --force`, porque el rebuild se niega a escribir un graph con menos
  nodos.
- La documentación en `documentation/` es parte del cambio, no un extra. Si el PR altera
  una decisión, actualiza la nota **y** el ADR que la sostiene.

---

## Documentación

`documentation/` es el cerebro del proyecto, en Markdown con frontmatter y `[[wikilinks]]`,
pensado para abrirse como vault en Obsidian.

| Documento | Contenido |
| --- | --- |
| [`arquitectura.md`](documentation/arquitectura.md) | Índice del sistema: paquetes, modelo de dominio, mapa de ADRs |
| [`capa-de-datos.md`](documentation/capa-de-datos.md) | Códec, repositorio, índice, audio, transcripción, enriquecimiento — y **los detalles que no son evidentes** |
| [`presentacion.md`](documentation/presentacion.md) | Composition root, features, navegación, view models, audio playback |
| [`design-system.md`](documentation/design-system.md) | Capas, tokens, `AdaptiveColor`, build de referencia |
| [`testing.md`](documentation/testing.md) | Cómo correr cada suite, qué depende del simulador, qué sólo se verifica en dispositivo |
| [`decisions/`](documentation/decisions/) | ADR 0001 – 0005, con contexto, decisión y consecuencias |
| [`releasing.md`](documentation/releasing.md) | Qué vive en el `README`, qué en el `CHANGELOG` y qué en la documentación, y cómo preparar la siguiente versión |

Y del graph:

- [`graphify-out/GRAPH_REPORT.md`](graphify-out/GRAPH_REPORT.md) — el informe del grafo de
  conocimiento del repo: resumen, comunidades, god nodes, conexiones inesperadas y huecos
  de conocimiento. **Cero ciclos de importación**, que es el dato que más cuesta
  conseguir en una arquitectura por capas.
- Los números viven en el informe, no aquí, porque este `README` está indexado en el graph:
  cualquier cifra citada en este fichero la invalida su propia actualización.
- `graphify query "<pregunta>"` para preguntas sobre el graph,
  `graphify explain "<nodo>"` para un nodo y sus vecinos,
  `graphify god-nodes --top 25` para los hubs arquitectónicos.

---

<div align="center">

**NoteSmart** — tus notas de voz, en Markdown, en tu dispositivo.

<sub>Hecho con SwiftUI, Swift 6 y la convicción de que la app
debería poder desaparecer sin que sus datos lo hagan.</sub>

</div>
