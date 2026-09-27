---
title: Local-first sin autenticación
tags: [producto, adr, local-first, privacidad, obsoleto-codigo]
created: 2026-09-26
status: aceptada
---

# ADR 0005 — Local-first sin autenticación

## Contexto

El proyecto nació con la plantilla de SwiftData, que trae `ModelContainer` de demo, una
`Item`, `ContentView` y una pantalla de `SignIn`. Nada de eso pertenece al producto: NoteSmart
no tiene cuentas, servidores ni sincronización.

## Decisión

- Sin autenticación. Se elimina `Presentation/Features/SignIn` completo.
- `Item` y el `ModelContainer` de demo se eliminan; el `ModelContainer` real lo crea el
  contenedor de DI para `NoteIndexRecord`.
- `WelcomeView` se convierte en onboarding de una sola vez: explica que el audio y la
  transcripción se quedan en el dispositivo, pide permiso de micrófono y, si el Vault no
  existe, lo crea. Sin registro, sin email, sin paso de "crear cuenta".
- `WelcomeView` pasa a ser `Settings` más una sección de privacidad, no una pantalla de
  entrada a la app. Hoy es `Features/More/ProfileView`: versión, almacenamiento, la nota
  de privacidad y el borrado del vault.

## Reconsideración: qué significa "Cerrar sesión"

El flujo de pantallas pediu una opción **Cerrar sesión** en el menú "Más". Eso choca de
frente con esta decisión, y no se resuelve fingiendo que la app tiene cuentas.

No hay servidor, así que cerrar sesión no puede ser invalidar un token ni terminar una
sesión remota. Lo único que un cierre de sesión honesto puede hacer en una app
local-first es **bloquear el vault hasta que el usuario vuelva a pedirlo**:

- `AppEnvironment.isLocked` es el estado. `lock()` lo pone, `unlock()` lo quita.
- Con el vault bloqueado, `RootView` vuelve a `SplashView(phase: .locked)`, el mismo
  splash con el que arranca la app, con un botón "Abrir vault".
- El environment **no** se reconstruye al bloquear, así que reabrir no paga un
  `ModelContainer` nuevo ni un `AVAudioEngine` nuevo. Bloquear no borra ni mueve nada.

El environment se conserva, el índice se conserva y el audio se conserva. Bloquear no
es un sitio de seguridad —cualquiera con el desbloqueo del iPhone puede volver a
entrar— y la interfaz no pretende lo contrario: el diálogo de confirmación dice
"Bloquea el vault en este dispositivo", no "protege tus notas".

Si en algún momento NoteSmart gana cuentas, esta decisión se sustituye: `isLocked`
deja de ser el mecanismo y pasa a serlo la sesión, y el ADR se reescribe.

## Consecuencias

- Nada de lo que el usuario dice sale del iPhone: audio, transcript y enriquecimiento son
  on-device. Es una promesa de producto, no un detalle de implementación, y por eso
  `NSMicrophoneUsageDescription` y `NSSpeechRecognitionUsageDescription` lo dicen explícitamente.
- El vault vive en `Documents/Vault` con `UIFileSharingEnabled`: si el usuario quiere sacarlo,
  puede hacerlo con Finder sin Exportar nada.
- `UIBackgroundModes` es `audio`, no `remote-notification`: no hay push.

## Ver también

- [[El vault markdown es la fuente de verdad]]
- [[IA on-device con piso determinista]]
