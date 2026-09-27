---
title: Presentación
tags: [presentacion, di, swiftui, viewmodel, navigation, audio]
created: 2026-09-26
status: actual
---

# Presentación

Target de la app: `DI` (composition root) + `Presentation` (features). No hay reglas de
negocio aquí; todo pasa por los use cases de [[note-smart-domain]] y las
implementaciones de [[capa-de-datos]]. Componentes de [[design-system]].

## Archivos

| Archivo | Responsabilidad |
| --- | --- |
| `DI/AppEnvironment.swift` | Composition root: el único lugar que sabe qué tipo concreto cumple cada protocol |
| `DI/AppErrorMessage.swift` | Traduce los tres enums de error del dominio a texto mostrable |
| `Presentation/AppRootView.swift` | Dueño del environment y del bootstrap, con pantalla de fallo |
| `Presentation/RootView.swift` | Ruta por estado del graph: splash, pantalla de captura o bloqueo |
| `Features/Splash/SplashView.swift` | Pantalla de arranque; también la del vault cerrado |
| `Features/Record/RecordHomeView.swift` | Pantalla principal: un botón de grabación y el acceso a "Más" |
| `Features/Record/RecordViewModel.swift` | Permiso, meter en vivo, stage del pipeline, reintento |
| `Features/More/MoreView.swift` | Grabaciones previas, perfil y cerrar sesión |
| `Features/More/ProfileView.swift` | Versión, almacenamiento, privacidad y borrado del vault |
| `Features/Recordings/RecordingsListViewModel.swift` | Lista el vault y ordena por `modified` |
| `Features/Recordings/RecordingsListView.swift` | Scaffold, tarjetas, `NavigationStack` por `NoteID` |
| `Features/NoteEditor/NoteEditorViewModel.swift` | Lectura y edición de una nota, tags, carpeta, tareas |
| `Features/NoteEditor/NoteEditorView.swift` | Cabecera, audio, prosa, checklist, transcript |
| `Features/NoteEditor/AudioPlaybackController.swift` | Reproducción y el reloj que sigue el transcript |
| `Presentation/Support/NoteCardModel.swift` | `Note` → primitivas de `DSNoteCard` |
| `Presentation/Support/NoteBody.swift` | Separa la prosa de las secciones que la app dibuja |

## El flujo de pantallas

```
NoteSmartApp
└── AppRootView                    dueña del environment y del bootstrap
    ├── SplashView(.preparing)     mientras se abre y sincroniza el vault
    ├── DSEmptyState(.failed)      si el vault no se puede abrir
    └── RootView                   enruta por environment.state
        ├── SplashView(.locked)    vault cerrado → botón "Abrir vault"
        └── RecordHomeView         pantalla principal
            ├── "Más" (arriba derecha) → MoreView
            │   ├── Grabaciones previas → RecordingsListView → NoteEditorView
            │   ├── Perfil              → ProfileView
            │   └── Cerrar sesión      → environment.lock() → SplashView(.locked)
            └── al guardar → NoteEditorView
```

## Decisiones que no son evidentes

**La pantalla principal es un botón y nada más.** Antes el `RecordPanel` flotaba
sobre `NotesListView`, así que el empty state "Vault vacío" y el micrófono competían
por la misma pantalla y no se sabía cuál era la app. Ahora `RecordHomeView` tiene un
solo control; el vault vive detrás de "Más" y su empty state también, porque es la
única pantalla que trata sobre el contenido del vault y la única que puede decir qué
significa un vault vacío.

**El `NavigationStack` vive en `RecordHomeView`, no en la lista.** Un `NavigationStack`
anidado por pantalla que se empuja desde un toolbar se rompe al hacer pop: el título y
el botón de atrás pertenecen a la pila interior. La ruta es un enum (`RecordHomeView.Route`)
en vez de varios tipos `Hashable` sueltos, así que un destino no puede empujarse en la
pila equivocada y el `switch` del compilador cubre el flujo entero.

**"Cerrar sesión" bloquea el vault, no termina una sesión remota.** NoteSmart no tiene
cuenta ni servidor, así que un cierre de sesión no puede significar nada remoto. Lo que
sí puede significar de forma honesta es bloquear los datos locales hasta que el usuario
los vuelva a pedir, y eso es lo que hace `environment.lock()`: el mismo
`SplashView` con fase `.locked`. Ver [[Local-first sin autenticación]].

**El splash tiene duración mínima (450 ms).** Abrir el vault suele tomar milisegundos;
por debajo de eso la pantalla de arranque parpadea un frame y se lee como un glitch en
vez de como una apertura. Se mide desde antes de construir el `ModelContainer`, así que
un disco lento también recibe un splash legible.

**El `Task` del pipeline retiene al view model a propósito.** Si el usuario navega
mientras se transcribe, la nota se guarda igual. Perder el audio de alguien porque
salió de la pantalla sería peor que dejar un `@State` huérfano. Esa retención es
deliberada; la de las tareas de *meter* no, y por eso `startMetering()` y
`runPipeline()` capturan el environment y sólo toman `self` dentro del cuerpo de cada
iteración. Con `guard let self` encima del `for await`, la tarea y el view model se
retienen mutuamente para siempre.

**El graph tiene un ciclo y se rompe en un solo punto.** `FileNoteRepository` refresca
el índice en cada escritura y `VaultIndexer` necesita el repositorio para rescannear.
Ninguno se puede construir primero con el otro en la mano, así que `AppEnvironment`
construye ambos y los enlaza con `attachIndex` una vez, antes de leer o escribir nada.

**El `ModelContainer` no se adjunta a la escena.** El índice es un detalle
implementación de la búsqueda: la lista lee el repositorio, no SwiftData. Si la
`Presentation` no importa SwiftData, nadie puede engancharle un `@Query` por descuido.

**`AppEnvironment` expone protocols, no tipos concretos.** `repository`, `search`,
`recorder`, `transcriber` y los dos enrichers se declaran como `any NoteRepository`,
`any NoteSearch`, etc. Los pares concretos quedan `private` para enlazar el ciclo y
sincronizar el índice al arrancar. El efecto es que `RecordViewModel`,
`RecordingsListViewModel` y `NoteEditorViewModel` **no importan `NoteSmartData`**: si
alguien intenta llamar un método que sólo existe en la implementación, el compilador
lo rechaza. La regla 3 del [[Arquitectura en capas y reglas de dependencia]] queda
garantizada por el compilador y no por la convención.

**`prepare()` es idempotente.** Crea el vault, enlaza el índice y sincroniza. Se puede
volver a llamar tras un cambio de fase de escena y cuesta un `fetchCount`, no un
rescan.

**Los view models se crean en `.task(id: environment.state)`.** `@Environment` no
existe en `init`, así que crearlos en la propiedad `@State` los dejaría sin
dependencias. El `id` hace que el task corra una vez, cuando el graph pasa a `.ready`.

**La lista navega por `NoteID`, no por ruta.** Renombrar o mover cambia el path pero
nunca la identidad, así que una nota abierta sobrevive a que le cambien el título por
debajo.

**La lista lee el repositorio, no el índice.** El markdown es la fuente de verdad y el
índice va milisegundos detrás de una escritura.

**El título se renombra con `RenameNote`, no con un `save`.** Un título nuevo es un
nombre de archivo nuevo, y esa decisión es del vault.

**Las tareas salen de `MarkdownEditing.tasks(in:)`, no de un parser en la app.** La
lista se dibuja con el mismo parser que cuenta para `toggleTask(in:at:)`. Un segundo
scan con una regla ligeramente distinta acabaría marcando la línea equivocada.

**`NoteBody` recorta las secciones que la app dibuja.** `CreateNoteFromRecording`
escribe `## Action items` y `## Transcript`; el editor las renderiza como checklist y
timeline, así que se recortan del markdown. Si no, cada action item aparecería dos
veces: como texto `- [ ]` y como control que funciona. Un `##` escrito por el usuario
no se recorta en el editor — sólo en el teaser de la tarjeta.

**El transcript se dibuja desde `note.transcript`, no desde el markdown.** Así cada
segmento puede resaltarse mientras suena el audio y ser tocable para hacer seek.

**`AudioPlaybackController` hace polling, no KVO.** `AVPlayer` pediría un observer
periódico que hay que desmontar en algún lado; un `Task` cancelable se para solo
cuando acaba la reproducción o desaparece la pantalla. No hay observer que se fugue.

**El fallo del pipeline deja el `.m4a` en el vault.** `AudioEngineRecorder.cancel()`
sólo borra el archivo si la grabación sigue en curso. El audio es del usuario: que la
transcripción fallara no es motivo para borrarlo.

**No hay pause/resume en la UI aunque el protocol los tenga.** `DSRecordingButton` es
un control de dos estados — grabar y parar — y un tercer estado sin desenho sería un
botón sin forma. Cuando se quiera, se añade el estado al design system primero.

**`SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY` está activo.** Usar un miembro de
otro módulo obliga a importarlo explícitamente: `NoteCardModel` importa `DSAtoms`
para `DSBadge.Tone` y `DSOrganisms` para `DSNoteCard`. Duplicado, pero cada archivo
declara lo que usa.

**Los tokens de color no son `Color`.** `Palette.accent` es un `AdaptiveColor`, un
`ShapeStyle` que lleva las dos apariencias y las resuelve en draw time. Casi todo se
usa igual (`foregroundStyle`, `fill`, `background`, `tint`), pero `Text.strikethrough`
exige un `Color` de verdad, así que `NoteEditorScreen` tiene
`@Environment(\.self) private var environment` y llama
`Palette.textTertiary.resolved(in: environment)`. Es el mismo apaño que hace
`dsGlass` adentro del design system. Los tokens también ya no son `View`: donde
hacían falta como fondo, va `Rectangle().fill(Palette.surfaceSunken)`. Ver
[[Design System]].

## Tests

`NoteSmart/NoteSmartTests/NoteSmartTests.swift` — `NoteCardModelTests` (mapeo de
tarjeta, preview que descarta resumen y secciones, fallback al transcript, conteo de
tareas pendientes, badge de procedencia) y `NoteBodyTests` (recorte de secciones
generadas, `##` del usuario, teaser, cuerpo vacío). Son funciones puras, pero viven
en el target de la app y necesitan simulador para correr.

## Ver también

- [[Arquitectura]] — dónde encaja este target
- [[Capa de datos]] — los protocols que esta capa consume
- [[Design System]] — los componentes que esta capa compone
- [[Testing]] — cómo correr cada suite
