# Changelog

Todas las novedades de NoteSmart se registran en este fichero.

El formato sigue [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/), y el
versionado sigue [Semantic Versioning](https://semver.org/lang/es/).

Los enlaces de los commits son relativos al repositorio, así que el changelog se lee
igual clonado o en la web.

---

## [No publicado]

Nada todavía.

---

## [1.0.0] — 2026-09-27

Primer release de NoteSmart. App iOS local-first que graba notas de voz, las transcribe y
enriquece en el dispositivo, y las guarda como Markdown en un vault compatible con
Obsidian. Sin cuentas, sin servidores, sin red.

`PRODUCT_BUNDLE_IDENTIFIER` `dev.normansanchez.NoteSmart` · `MARKETING_VERSION` 1.0 ·
`CURRENT_PROJECT_VERSION` 1 · deployment target iOS 27.0 · Xcode 27.0.

### Añadido

#### Núcleo del producto

- **Captura de audio** con `AVAudioEngine`: AAC/M4A escrito en streaming a disco, medidor
  de nivel en vivo durante la grabación, `pause`/`resume` en el protocol (sin UI todavía),
  y `meter()` que devuelve un stream nuevo por captura.
- **Transcripción on-device** con `SpeechTranscriber`: descarga de modelo visible y
  cancelable, segmentos con `TimeRange` por frase, y `TranscriptionProgress` en streaming.
- **Enriquecimiento con `FoundationModels`**: `NoteEnrichmentDraft` como `@Generable`
  —título, resumen, tags, action items y `cleanedMarkdown`—, con `streamResponse`
  proyectado a `EnrichmentProgress` para que la UI vea el título antes de que termine el
  resto.
- **Piso determinista** `RuleBasedNoteEnricher`: sin modelo y sin descarga, deriva título
  (primera frase sin fillers, cortada en frontera de palabra), resumen (primeras dos
  frases), tags (los `#tag` dichos más los sugeridos) y tareas (frases con señales de
  compromiso, en español e inglés).
- **Pipeline** `CreateNoteFromRecording` con progreso como
  `AsyncThrowingStream<Stage, Error>`: `.installingModel` → `.transcribing` →
  `.enriching` → `.saved`. Si la transcripción o el enriquecimiento fallan, la nota se
  guarda igual.
- **Vault Markdown en `Documents/Vault`**, con frontmatter plano y deliberadamente
  pequeño, `id` persistente, transcript JSON en el frontmatter (fuera del body) y
  `Documents/Vault/Recordings` para el audio.
- **Escrituras atómicas** y desambiguación de nombres por sufijo numérico
  (`"Nota"`, `"Nota 2"`, `"Nota 3"`), con recorte en frontera de palabra y slug ASCII sin
  diacríticos.
- **Búsqueda** con sabor a BM25 sobre un índice SwiftData reconstruible: ranking con
  título por encima del cuerpo, `includeBody` opt-in, scope por carpeta y por tags,
  snippets, y resolución de wikilinks insensible a mayúsculas con links colgantes
  tolerados.
- **Editor de notas** con reproducción de audio, resaltado del segmento activo y seek
  tocando el transcript, checklist de tareas extraída del markdown, tags y cambio de
  carpeta.
- **Lista de grabaciones** con tarjetas, carpetas anidadas, orden por `modified` y
  navegación por `NoteID` en vez de por ruta.
- **Perfil** con versión, sistema, uso real del vault (nº de notas, bytes de audio,
  ubicación) y borrado total de datos con confirmación.
- **"Cerrar sesión"** como bloqueo del vault local: vuelve al splash en fase `.locked` y
  pide "Abrir vault" de nuevo.
- `AppEnvironment` con `live()` para producción e `inMemory()` para previews y tests de
  UI, y `prepare()` idempotente.

#### Arquitectura

- **Tres paquetes SPM locales** con dependencias en una sola dirección:
  `NoteSmartDomain` (Swift puro), `NoteSmartData` (disco, SwiftData, AVFAudio, Speech,
  FoundationModels) y `NoteSmartDesignSystem` (cinco targets de Atomic Design).
- **Clean Architecture + MVVM** con `@Observable` como state holder. La regla de
  dependencia crítica la hace cumplir el compilador: `AppEnvironment` publica
  `any NoteRepository`, `any NoteSearch`, `any AudioRecorder`, `any Transcriber` y deja
  los tipos concretos en `private`, así que ningún view model puede llamar un método que
  sólo exista en la implementación.
- **Domain**: 6 value objects y entities, 7 protocols, 4 casos de uso
  (`CreateNoteFromRecording`, `TranscribeRecording`, `EnrichTranscript`,
  `MarkdownEditing`) y 3 enums de error tipados.
- **Cinco ADRs** documentando las decisiones que gobiernan el proyecto: arquitectura en
  capas, vault markdown como fuente de verdad, IA on-device con piso determinista,
  Liquid Glass sólo en el chrome, y local-first sin autenticación.
- **Grafo de conocimiento del repo** con `graphify`: 1 228 nodos, 2 817 aristas, 67
  comunidades, god nodes documentados y **cero ciclos de importación**.

#### Design System

- **Cinco capas** con dependencias que sólo fluyen hacia arriba, y los límites entre
  targets SPM *son* la arquitectura:
  `DSTokens` → `DSAtoms` → `DSMolecules` → `DSOrganisms` → `DSTemplates`.
- **Tokens**: `Palette`, `Spacing`, `Typography`, `Motion`, `Metrics`, `GlassConfig`.
- **`AdaptiveColor`**: cada token de color lleva sus dos apariencias y conforma a
  `ShapeStyle`, de modo que SwiftUI lo resuelve en draw time contra el environment real.
  Cero UIKit, cero asset catalog.
- **14 componentes**: `DSButton`, `DSIconButton`, `DSChip`, `DSBadge`, `DSCard`,
  `DSTextField`, `dsGlass`, `DSRecordingButton`, `DSAudioLevelMeter`, `DSProgressBar`,
  `DSEmptyState`, `DSSectionHeader`, `DSTagRow`, `DSFlowLayout`, `DSNoteCard`,
  `DSRecordingPanel`, `DSSearchResultRow`, `DSReadingColumn`, `DSListScaffold`,
  `DSFloatingToolbar`.
- `SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY` activado: usar un miembro de otro
  módulo obliga a importarlo explícitamente.

#### Interfaz

- **Pantalla de captura con un solo control** (`RecordHomeView`). Antes el panel de
  grabación flotaba sobre la lista de notas, así que el empty state y el micrófono
  competían por la misma pantalla y no se sabía cuál era la app.
- **Splash con duración mínima de 450 ms** medida desde antes de construir el
  `ModelContainer`, para que un disco lento también produzca una apertura legible en vez
  de un parpadeo de un frame.
- `DSRecordingPanel` con badge de procedencia —"IA editó esto" vs. regla determinista— y
  botón **"Reintentar" opcional**: sólo se dibuja si quien lo usa provee el callback.
- Feedback progresivo en las tres etapas del pipeline, con acción de reintento y
  conservación del audio aunque la transcripción falle.
- `AudioPlaybackController` con polling cancelable en vez de KVO: no hay observer que se
  pueda fugar.

#### Tests

- **110 casos `@Test`** de swift-testing en 10 archivos, ~1 900 líneas.
- `NoteSmartDomain` corre con `swift test` en el Mac, sin simulador.
- Cobertura de códec Markdown ida y vuelta, naming con sufijos, concurrencia del
  repositorio (8 guardados simultáneos del mismo título reclamando nombres distintos),
  errores de delete, colisiones de move, indexado y reindexado, búsqueda multinivel,
  grafo de wikilinks, y los tres casos de uso del pipeline con fakes —incluido el camino
  completo de fallback sin IA—.
- `AudioPlaybackController` con reloj que sigue el transcript y resaltado del segmento
  activo.
- **Suite de datos enlazada al target de la app** por symlinks en
  `NoteSmart/NoteSmartTests/_DataTests/`, para que un solo `xcodebuild test` en un iPhone
  real corra todo: `xcodebuild` no puede ejecutar un `testTarget` de SPM sin host app en
  un dispositivo físico.

#### Documentación

- `documentation/` como cerebro del proyecto en Obsidian: `arquitectura.md`,
  `capa-de-datos.md`, `presentacion.md`, `design-system.md`, `testing.md`, más las cinco
  ADRs enlazadas con `[[wikilinks]]`.
- 26 cadenas de copy en `Localizable.xcstrings`.
- `README.md` con arquitectura, formato de nota, rutas de build y de test, y una lista
  honesta de limitaciones conocidas.

### Corregido

Bugs encontrados y resueltos durante el desarrollo. Ninguno es cosmético: todos producen
pérdida de datos, pérdida de audio o una app que parece funcionar y no funciona.

#### Audio

- **El `guard` de `start()` estaba invertido.** `start()` procedía sólo si el motor no
  corría **ni** se estaba capturando, lo que hacía que **el primer toque no produjera
  nada**: no había motor, ni tap, ni fichero, y `stop()` acababa en `emptyRecording`. Los
  tres síntomas a la vez —el `.m4a` no se guardaba, no había transcripción, no había
  markdown—. Los guards de `start`/`resume` ahora son simétricos, no intercambiados.
- **Desajuste de canales en el audio, y cada `write` lanzaba.** `start()` forzaba mono con
  `min(format.channelCount, 1)` mientras el tap entregaba estéreo, así que el
  `processingFormat` del `.m4a` y el del tap nunca coincidían. Ahora se construye un
  único `AVAudioFormat` float32 no entrelazado y se usa para `installAudioTap` **y** para
  `makeFile`, dejando que `AVAudioEngine` convierta desde el hardware.
- **Un error de escritura se tragaba con `try?`.** Un buffer descartado es
  indistinguible del silencio para el usuario, y producía un `.m4a` jugable de **0
  frames** que sólo se manifestaba mucho después, cuando la transcripción fallaba sin
  rastro de la causa. Ahora el primer error queda latcheado en `writeError`, y `stop()` lo
  reporta y borra el fichero.
- **La duración salía del reloj de pared en vez de los frames.** Una captura que no
  capturó nada devolvía una duración plausible y la UI la aceptaba. `finish()` devuelve
  ahora `frameCount`, y `stop()` lanza `emptyRecording` y borra el `.m4a` si es 0.
- **`meter()` se cacheaba entre capturas.** `AsyncStream` es de un solo consumidor, así
  que de la segunda grabación en adelante no había ni cronómetro ni onda. Cada `meter()`
  devuelve un stream nuevo y lo adjunta a la sesión.
- **El tap de audio usaba la API vieja.** Migrado a
  `installAudioTap(onBus:bufferSize:format:tapProvider:)`, que lanza en vez de devolver
  `Void` y entrega `AVReadOnlyAudioPCMBuffer`. El RMS itera por índice porque
  `Span<Float>` no expone `prefix(_:)`.
- **`removeTap` se llamaba sobre buses sin tap**, lo que lanza una excepción Objective-C
  —no un error Swift— y no se puede capturar en un `throws`. `tearDown()` va ahora por un
  flag `tapInstalled`.
- **Carrera de datos en la sesión de captura.** `CaptureSession` tiene su propio `NSLock`
  porque el tap llega en la cola de render en tiempo real, no en el actor: sin el lock,
  escribir el buffer y leer `isCapturing` desde dos hilos es una carrera.

#### Markdown y datos

- **El título conservaba el punto final.** `splitSentences` guarda el terminador a
  propósito porque un resumen pegado de frases enteras tiene que leerse como prosa, pero
  un título vive en una fila de lista junto a otros títulos, y una fila que termina en
  punto parece una frase cortada en vez de una etiqueta. `makeTitle` quita los `.!?…`
  finales; `makeSummary` los conserva. El test que fijaba este comportamiento llevaba
  tiempo compilado sin ejecutarse, así que el punto colgaba ahí sin que nadie lo notara.
- **Tests que se compilaban pero nunca se ejecutaban.** `RuleBasedNoteEnricherTests` pasó
  meses reportando verde sin correr nunca, por el bug del título de arriba.
  `AudioEngineRecorderTests` estuvo semanas sin symlink. Los dos casos quedaron
  documentados como regla: añadir un test a `NoteSmartDataTests` implica añadir su
  symlink.
- **Los `.md` sueltos en `Recordings` aparecían como notas.** `markdownFiles(in:)` y
  `folderPaths(in:)` ahora saltan esa carpeta: los recordings no son notas.
- **Un `.md` sin frontmatter aparecía como nota rota** en vez de saltarse.

#### Build

- **`NoteSmartData` compilaba para macOS con 516 avisos.** `AVAudioSession`, los
  frameworks de Speech on-device y FoundationModels no tienen forma en macOS, así que el
  módulo se type-chequeaba contra el suelo por defecto de macOS y emitía un aviso por
  cada referencia a `Model`, `Predicate`, `Generable`, `SpeechTranscriber`… Parecían 516
  problemas distintos cuando había uno solo. Arreglo de raíz: `SUPPORTED_PLATFORMS` pasó
  a `"iphoneos iphonesimulator"` con `SDKROOT = iphoneos`, más un
  `#if !os(iOS) #error(…)` en `Platform.swift`. "My Mac" ahora aparece como destino
  **incompatible** con un mensaje, en vez de como un build roto.
- **`NoteSmart.entitlements` arrastraba capacidades de la plantilla** —`aps-environment` y
  CloudKit— que la app no usa tras eliminar la sincronización.

#### Design System

- **`Palette` medía el contraste contra el environment equivocado.** Los tokens eran
  colors dinámicos de `UIColor` y `luminance` leía los canales con
  `UIColor(self).getRed(...)`, que sobre un color dinámico mide contra
  `UITraitCollection.current` — y dentro de SwiftUI **no** es el environment de la vista.
  `readableForeground` sobre una superficie oscura podía estar calculando la variante
  clara. Ahora los tokens son `AdaptiveColor`, un `ShapeStyle` que SwiftUI resuelve en
  draw time.
- **Colisión de nombres con SwiftUI en iOS 27.** `Glass.swift` pasó a definir
  `GlassConfig` (SwiftUI ya define `Glass`) y `Layout.swift` a `Metrics.swift`
  (existe `SwiftUI.Layout`), para no producir ambigüedad de tipo dentro del Design
  System.
- **El botón "Reintentar" no reintentaba.** `DSRecordingPanel` lo pintaba siempre con una
  acción vacía; ahora `onRetry` es opcional y sólo se dibuja cuando quien lo usa lo
  provee.

#### Presentación

- **`NavigationStack` anidado por pantalla.** El título y el botón de atrás pertenecen a
  la pila interior, así que se rompían al hacer pop. Ahora vive en `RecordHomeView` y la
  ruta es un enum.
- **Fuga de memoria en las tareas de meter.** Con `guard let self` encima del `for await`,
  la tarea y el view model se retenían mutuamente para siempre. `startMetering()` y
  `runPipeline()` capturan el environment y sólo toman `self` dentro del cuerpo de cada
  iteración. La retención del view model por la tarea del pipeline sí es deliberada:
  perder el audio de alguien porque salió de la pantalla sería peor que dejar un `@State`
  huérfano.
- **Los checkmarks se marcaban en la línea equivocada.** La lista escaneaba el markdown
  con una regla propia mientras `toggleTask` usaba otra. Ambas salen ahora del mismo
  parser, `MarkdownEditing.tasks(in:)`.
- **Cada action item aparecía dos veces en el editor**, como texto `- [ ]` y como control
  que funciona. `NoteBody` recorta del markdown las secciones que la app dibuja
  (`## Action items`, `## Transcript`); un `##` escrito por el usuario no se recorta en el
  editor, sólo en el teaser de la tarjeta.
- **Un `.m4a` de 0 frames pasaba por una duración plausible** en la lista. Ver la sección
  de audio.
- **El fallo del pipeline borraba el audio del usuario.** `cancel()` ahora sólo borra el
  archivo si la grabación sigue en curso: que la transcripción falle no es motivo para
  tirar su audio.

#### Producto

- **Se eliminó el scaffolding de la plantilla de SwiftData**: `Item`, el `ModelContainer`
  de demo, `ContentView` y el target completo de `SignIn`. NoteSmart no tiene cuentas,
  servidores ni sincronización, y nada de eso pertenecía al producto. `WelcomeView` pasó
  a ser onboarding de una sola vez: explica la privacidad, pide el micrófono y crea el
  vault si falta.
- **"Cerrar sesión" no tenía un significado honesto** en una app sin cuenta ni servidor.
  Ahora bloquea los datos locales hasta que el usuario los vuelva a pedir, que es lo
  único que ese botón puede significar de verdad.

### Añadido — resumen numérico

| Métrica | Valor |
| --- | --- |
| Módulos | 3 paquetes SPM + 1 target de app |
| Targets SPM | 7 (`NoteSmartDomain`, `NoteSmartData` + 5 del Design System) |
| Archivos Swift de producción | 68 |
| Líneas de producción | 6 437 |
| Líneas de test | 1 921 |
| Casos de test | 110 |
| ADRs | 5 |
| Componentes de Design System | 20 |
| Cadenas localizadas | 26 |
| Ciclos de importación | 0 |

### Seguridad y privacidad

- Ninguna nota, grabación o transcripción sale del dispositivo. No hay backend, ni
  analytics, ni telemetría, ni tráfico de red de ningún tipo.
- Sin autenticación: ni registro, ni email, ni Sign in with Apple.
- Permisos mínimos: micrófono y reconocimiento de voz, y sólo al tocar grabar.
- El vault es visible desde Files (`UIFileSharingEnabled`) y se puede abrir con cualquier
  editor de Markdown. Nada de formato propietario.
- Desinstalar la app elimina el vault, y la pantalla de perfil lo dice sin eufemismos.

### Notas de esta versión

- **Requiere un iPhone real para ejercitar el pipeline completo.** El simulador reporta
  el input del micrófono con sample rate 0, y tanto `SpeechTranscriber.isAvailable` como
  `SystemLanguageModel.availability` dan `false` o no disponible ahí.
- **Dos comportamientos sólo se pueden verificar en dispositivo**: que el `.m4a` escrito
  tenga frames, y que la segunda captura muestre onda y cronómetro.
- **`NoteSmartUITests` sigue sin arrancar** (`No se pudo instalar
  NoteSmartUITests-Runner`, problema de firma del runner). Las rutas de `xcodebuild test`
  necesitan `-only-testing:NoteSmartTests`.
- **El flujo de pantallas no tiene tests de UI.** Es el hueco más grande de la suite, y
  el primero que debería cerrarse: el bug del `guard` invertido de `start()` llegó hasta
  producción precisamente porque nada ejercitaba la ruta del botón.
- **El repositorio no declara licencia todavía.**
- El contador de XCTest muestra `Executed 0 tests` mientras los tests pasan, porque las
  suites usan swift-testing, que corre su propio runner. Hay que leer
  `Test case '…' passed` o `✘`.

[No publicado]: https://github.com/NormanSanchezDev/voice-smart-ios/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/NormanSanchezDev/voice-smart-ios/releases/tag/v1.0.0
