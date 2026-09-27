---
title: Testing
tags: [testing, xcodebuild, simulador, ci]
created: 2026-09-26
status: actual
---

# Testing

| Suite | Comando | Depende de simulador |
| --- | --- | --- |
| `NoteSmartDomain` | `cd Packages/NoteSmartDomain && swift test` | no |
| `NoteSmartData` | `cd NoteSmart && xcodebuild test -scheme NoteSmart -destination 'id=<udid>' -only-testing:NoteSmartTests` | no, corre en dispositivo |
| `NoteSmartDesignSystem` | `xcodebuild build -scheme NoteSmartDesignSystem-Package -destination 'generic/platform=iOS Simulator'` | sólo para compilar |
| `NoteSmart` (app) | igual que `NoteSmartData`: los tests de datos llegan por symlink | no, corre en dispositivo |

## La ruta que funciona: tests en un iPhone real

El simulador de esta máquina está roto (ver más abajo), pero hay un iPhone conectado y
compatible, y por él corren **todos** los tests de datos y de presentación:

```
cd NoteSmart
xcodebuild test -scheme NoteSmart -destination 'id=<udid>' -only-testing:NoteSmartTests
```

`xcodebuild -scheme NoteSmart -showdestinations` lista el UDID. 72 tests, `TEST SUCCEEDED`.

Dos cosas que conviene saber sobre este camino:

- **Sin `-only-testing` falla**, y no por los tests: el target `NoteSmartUITests` no se
  instala (`No se pudo instalar NoteSmartUITests-Runner`, problema de firma del runner).
  Como `NoteSmartUITests` sigue con el scaffolding de la plantilla de Xcode, lo
  razonable es excluirlo hasta que tenga tests que valgan.
- **El contador de XCTest dice 0 mientras los tests pasan.** Las suites usan
  `swift-testing`, que corre su propio runner; el `Executed 0 tests` de XCTest no dice
  nada del resultado. Hay que leer `Test case '…' passed` o `✘`.

Esto cierra el hueco más grande de la suite: `RuleBasedNoteEnricherTests` llevaba meses
compilándose sin ejecutarse nunca, y tenía un bug real escondido (ver
[[Capa de datos]]). Un test que no corre no es un test.

## Por qué el dominio corre en el Mac

`NoteSmartDomain` no importa SwiftUI ni frameworks de Apple, así que `swift test` funciona
directo. `NoteSmartData` sí importa SwiftData, AVFAudio, Speech y FoundationModels, y su
manifest declara `platforms: [.iOS(.v27)]`: necesita un destino iOS.

## `NoteSmartData` es iOS-only, y lo dice

`NoteSmartData` usa `AVAudioSession`, los frameworks de Speech on-device y
FoundationModels. Ninguno existe en macOS. Por eso `Sources/NoteSmartData/Platform.swift`
abre con un `#error` bajo `#if !os(iOS)`.

Sin ese `#error`, un `xcodebuild -destination 'generic/platform=macOS'` o un `swift build`
en el Mac type-checkeaba el módulo contra el suelo por defecto de macOS y emitía **516
avisos** de availability —uno por cada referencia a `Model`, `Predicate`, `Generable`,
`SpeechTranscriber`…— y después errores duros. Parecían 516 problemas distintos cuando
había uno solo.

El arreglo de raíz está en el target de la app, que declaraba
`SUPPORTED_PLATFORMS = "iphoneos iphonesimulator macosx xros xrsimulator"` con
`SDKROOT = auto`: eso hacía que Xcode evaluara los paquetes para macOS. Ahora es
`SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"` y `SDKROOT = iphoneos`, y "My Mac"
aparece como destino **incompatible** con un mensaje, en vez de como un build roto.

`NoteSmartDomain` y `NoteSmartDesignSystem` no llevan el `#error`: el dominio es Foundation
puro y el design system es SwiftUI, y ambos compilan en cualquier parte.

## Compilar sin correr

`xcodebuild build-for-testing -scheme NoteSmartData -destination 'generic/platform=iOS Simulator'`
compila el bundle de tests contra el SDK de iOS sin necesidad de un device. Es el atajo
útil cuando sólo se quiere comprobar que los tests compilan.

## Tests de host en dispositivo

Un `testTarget` de SPM sin host app no puede correr en un dispositivo físico:

```
Tool-hosted testing is unavailable on device destinations.
```

Para correr en hardware hay que ejecutar el target de la app, que sí tiene host.

## Verificación que sólo se puede hacer en dispositivo

Dos comportamientos de `AudioEngineRecorder` no se pueden cubrir con un test en esta
máquina, y la razón es física: el simulador reporta el input del micrófono con sample
rate 0, así que `start()` lanza antes de abrir nada.

1. **El `.m4a` escrito tiene frames.** Se comprueba grabando unos segundos, parando y
   mirando `ffprobe` o el propio panel: la duración tiene que salir de los frames del
   fichero, no del reloj de pared. Antes del arreglo, un `.m4a` de 0 frames pasaba por
   una duración plausible.
2. **La segunda captura muestra onda y tiempo transcurrido.** `meter()` devuelve un
   stream nuevo por captura; con el stream cacheado, de la segunda grabación en adelante
   no había ni cronómetro ni onda.

También fuera del simulador: `SpeechTranscriber.isAvailable` y FoundationModels. En
simulador ambas dan `false`/no disponible, así que el pipeline completo no se puede
ejercitar ahí. Un fallo de transcripción en dispositivo con un locale no soportado es
comportamiento esperado, no un bug: `Transcriber.isAvailable` es la guarda.

## Bloqueo conocido en esta máquina

El store de simuladores es un symlink:

```
~/Library/Developer/CoreSimulator → /Volumes/MacSSD/DeveloperCaches/Xcode/CoreSimulator
```

`CoreSimulatorService` recibe `EPERM` al escribir en `/Volumes/MacSSD`, así que no puede
crear devices (`Device was allocated but was stuck in creation state`) ni listar los 19
devices registrados en `device_set.plist`. Un device set en el disco interno
(`xcrun simctl --set <path> create …`) funciona, pero `xcodebuild` no acepta un device set
alterno, así que no sirve para `xcodebuild test`.

**Esto ya no bloquea nada**: la suite corre entera contra un iPhone real (ver la ruta más
arriba). El simulador sólo sigue haciendo falta para iterar rápido sobre UI, y el store se
puede crear de nuevo cuando `/Volumes/MacSSD` acepte escrituras.

## Qué cubren los tests

- [[Capa de datos]] lista el detalle por suite.
- [[Presentación]] lista el detalle por suite.
- El dominio cubre value objects, códec Markdown, casos de uso con fakes de audio,
  transcripción y enriquecimiento, incluyendo el camino de fallback sin IA.

## Tests de la app

`NoteSmartTests` mezcla dos cosas:

- `NoteSmartTests.swift` — pruebas de la capa de presentación, escritas contra las
  funciones puras de mapeo.
- `_DataTests/` — symlinks a los seis archivos de `NoteSmartDataTests`, para que el
  target de la app también los ejecute.

Los symlinks existen porque `xcodebuild` no puede correr un `testTarget` de SPM sin
host app en un dispositivo, y porque tener un solo `xcodebuild test` para todo es más
barato que dos. Si se edita un test de datos, se edita en `Packages/NoteSmartData`, no
en el symlink.

Cuando se añade un archivo de test nuevo a `NoteSmartDataTests`, hay que añadir su symlink
o no se ejecuta nunca. `AudioEngineRecorderTests` se creó después de los symlinks
existentes y estuvo semanas sin correr; el fallo de `RuleBasedNoteEnricherTests/title()`
apareció justo en la primera ejecución real de la suite.

## Cobertura honesta de la navegación

El flujo de pantallas —splash, un botón, "Más", grabaciones previas, perfil, cerrar
sesión— **no tiene tests**. Es el hueco más grande de la suite y el primero que debería
cerrarse: la navegación es exactamente lo que un test de UI comprueba barato, y el bug del
`guard` invertido de `start()` llegó hasta producción precisamente porque nada
ejercitaba la ruta del botón.

Ahora hay dos motivos para cerrarlo, y uno ya no es el store roto. En un iPhone real el
target `NoteSmartUITests` tampoco arranca: el runner no se puede instalar
(`No se pudo instalar NoteSmartUITests-Runner`). Es un problema de firma, no del
simulador, así que sigue pendiente sin importar que el store se repare.
