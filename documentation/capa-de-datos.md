---
title: Capa de datos
tags: [data, vault, audio, speech, swiftdata, testing]
created: 2026-09-26
status: actual
---

# Capa de datos

Implementación de los protocols de [[note-smart-domain]] sobre el sistema de archivos,
SwiftData, AVFAudio, Speech y FoundationModels. Decisiones en
[[El vault markdown es la fuente de verdad]] e [[IA on-device con piso determinista]].

## Archivos

| Archivo | Responsabilidad |
| --- | --- |
| `DocumentsVaultLocator.swift` | Localiza `Documents/Vault` y `Vault/Recordings` detrás del protocol `VaultLocator` |
| `NoteMarkdown.swift` | Códec del archivo: frontmatter plano, transcript JSON, quoting y parsing |
| `NoteFileNaming.swift` | Slug ASCII, recorte en frontera de palabra, desambiguación con sufijo numérico |
| `FileNoteRepository.swift` | Actor del vault: lectura recursiva, escrituras atómicas, move, delete, indexado |
| `NoteIndexRecord.swift` | Proyección SwiftData de cada nota, reconstruible |
| `VaultIndexer.swift` | Búsqueda con sabor a BM25, tags y grafo de wikilinks |
| `AudioEngineRecorder.swift` | Grabación AAC/M4A con `AVAudioEngine`, meter en vivo, pause/resume |
| `OnDeviceTranscriber.swift` | `SpeechTranscriber` con `AssetInventory`, segmentos y tiempos |
| `OnDeviceNoteEnricher.swift` | `FoundationModels` con `@Generable` y streaming de progreso |
| `RuleBasedNoteEnricher.swift` | Piso determinista, sin modelo |

## Detalles que no son evidentes

**El indexer construye su propio `ModelContext`.** `VaultIndexer.init` recibe el
`ModelContainer`, no un contexto. `ModelContext` no es `Sendable`, así que un indexer que
tomara prestado el `mainContext` sería una carrera de datos esperando a ocurrir. Construirlo
dentro del actor además le da su propia cola, que es lo que mantiene fluida la escritura en
el campo de búsqueda.

**El transcript va en el frontmatter, no en el cuerpo.** El usuario puede reescribir la prosa
sin romper la reproducción del audio contra las palabras.

**El tap de audio usa la API nueva de iOS 27.** `installAudioTap(onBus:bufferSize:format:tapProvider:)`
lanza en vez de devolver `Void`, y entrega `AVReadOnlyAudioPCMBuffer`, cuyo `channelData(0)`
es un `enum ChannelData` con `Span<Float>` en vez de `UnsafePointer<Float>`. El RMS itera por
índice porque `Span` no expone `prefix(_:)`.

**La sesión de captura tiene su propio `NSLock`.** `CaptureSession` la usa porque el tap de
audio llega en la cola de render en tiempo real, no en el actor: sin el lock, escribir el
buffer y leer `isCapturing` desde dos hilos es una race.

**Un solo formato para toda la captura.** `start()` construye un `AVAudioFormat`
float32 no entrelazado a partir del formato del hardware, y usa *ese* tanto para
`installAudioTap` como para `makeFile`. `AVAudioEngine` convierte del hardware a ese
formato, y como el `.m4a` se construye con la misma disposition, `processingFormat` del
fichero y formato del tap son idénticos y `file.write(from:)` no puede fallar por un
desajuste de canales. La versión anterior forzaba mono con `min(format.channelCount, 1)`
mientras el tap entregaba estéreo, y cada `write` lanzaba.

**El título pierde el punto final, el resumen no.** `splitSentences` guarda el terminador
a propósito, porque un resumen pegado de frases enteras tiene que leerse como prosa. Un
título es lo contrario: vive en una fila de lista junto a otros títulos, y una fila que
termina en punto parece una frase cortada en vez de una etiqueta. `makeTitle` quita los
`.!?…` finales; `makeSummary` los conserva. El test que fijaba este comportamiento
(`RuleBasedNoteEnricherTests/title()`) llevaba tiempo compilado sin ejecutarse, así que el
punto colgaba ahí sin que nadie lo notara.

**Un error de escritura se latchea, no se traga.** `consume()` guardaba el resultado con
`try?`: un buffer descartado es indistinguible del silencio para el usuario, y producía
un `.m4a` jugable de 0 frames que sólo se manifestaba mucho después, cuando la
transcripción fallaba sin rastro de la causa. Ahora el primer error queda en
`writeError` y `stop()` lo reporta y borra el fichero.

**La duración sale del fichero, no del reloj.** `finish()` devuelve también
`frameCount`; `stop()` tira el `.m4a` y lanza `emptyRecording` si es 0. Antes la duración
caía al reloj de pared cuando el fichero estaba vacío, así que una captura que no
capturó nada devolvía una duración plausible y la UI la aceptaba.

**El `meter()` no se cachea.** `AsyncStream` es de un solo consumidor: guardar el
stream entre capturas dejaba a la segunda, la tercera y todas las siguientes sin
tiempo transcurrido ni onda. Cada `meter()` devuelve un stream nuevo y lo adjunta a la
sesión.

**Los guards de `start`/`resume` son simétricos, no intercambiados.** `start()` procede
sólo si el motor no corre **y** no se está capturando; `resume()` sólo si el motor no
corre **y** se sigue capturando (en pausa). Tener el de `resume` invertido hizo que
`start()` retornara sin hacer nada en el primer toque: no había motor, ni tap, ni
fichero, y `stop()` acababa en `emptyRecording`. El `.m4a` no se guardaba, no había
transcripción y no había markdown — los tres síntomas a la vez.

**`removeTap` sólo si se instaló.** `tearDown()` va por un flag `tapInstalled`:
`removeTap(onBus:)` sobre un bus sin tap lanza una excepción Objective-C, no un error
Swift, y no se puede capturar en un `throws`.

**Los recordings no son notas.** `markdownFiles(in:)` y `folderPaths(in:)` saltan la carpeta
`Recordings`; un `.md` suelto ahí no aparece en el listado.

## Tests

`Packages/NoteSmartData/Tests/NoteSmartDataTests`:

- `NoteFileNamingTests` — diacríticos, separadores repetidos, recorte en palabra, sufijos.
- `NoteMarkdownTests` — ida y vuelta, `id` persistente, títulos con comillas y saltos de
  línea, frontmatter escrito por otra herramienta, body con wikilinks y code fences,
  frontmatter ausente o sin cerrar.
- `FileNoteRepositoryTests` — crear, re-guardar sin duplicar, sufijos por título repetido,
  renombrarse a sí mismo, carpetas anidadas, `Recordings` excluida, delete y sus errores,
  move con colisión, y 8 guardados concurrentes del mismo título reclamando nombres distintos.
- `RuleBasedNoteEnricherTests` — título con fillers, truncado, párrafos, resumen, tags
  inline y sugeridos, action items en español e inglés, casos vacíos, determinismo.
- `VaultIndexerTests` — sincronizar, indexar, reindexar, notas borradas, archivos externos,
  búsqueda multinivel, body opt-in, ranking por título, scope de carpeta y de tags, queries
  de ruido, snippets, tags del vault y grafo con links colgantes y case-insensitive.
- `AudioEngineRecorderTests` — parar y cancelar un grabador que nunca arrancó, y que parar
  dos veces no levante. Ninguno necesita micrófono.

### Lo que `AudioEngineRecorderTests` no cubre

Que cada captura reciba un `meter()` nuevo y que el `.m4a` tenga frames **requieren un
nodo de entrada real**. El simulador reporta un input con sample rate 0, así que un test
escrito ahí sería un test que no puede fallar. Esos dos casos se verifican en dispositivo;
`documentation/testing.md` tiene el procedimiento.

Los seis archivos de esta carpeta están enlazados en `NoteSmart/NoteSmartTests/_DataTests/`,
así que `xcodebuild test -scheme NoteSmart -destination 'id=<udid>'` corre la suite
completa contra un iPhone real. Los symlinks son la parte fácil de olvidar: añadir un
archivo de test aquí sin añadir su symlink deja el test sin ejecutarse, que es como este
package pasó meses reportando verde.

## El paquete es iOS-only

`Sources/NoteSmartData/Platform.swift` abre con `#if !os(iOS) #error(…)`. No es
ceremonia: `AVAudioSession`, los frameworks de Speech on-device y FoundationModels no
tienen forma en macOS. Sin el `#error`, compilar este package para macOS emitía 516 avisos
de availability y luego errores duros, lo que se leía como si faltara algo en cada
archivo en vez de "este package no es para aquí". El arreglo de raíz está en el target de
la app: `SUPPORTED_PLATFORMS` pasó a `"iphoneos iphonesimulator"` con `SDKROOT = iphoneos`.

`NoteSmartDomain` y `NoteSmartDesignSystem` no llevan ese `#error` a propósito: son
portables, y limitarlos sería tirar una propiedad real del diseño.

## Ver también

- [[Arquitectura en capas y reglas de dependencia]]
- [[Design System]]
