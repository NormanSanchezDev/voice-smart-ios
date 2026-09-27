---
title: IA on-device con piso determinista
tags: [arquitectura, adr, ia, foundation-models, speech, fallback]
created: 2026-09-26
status: aceptada
---

# ADR 0003 — IA on-device con piso determinista

## Contexto

El enriquecimiento de notas (título, resumen, tags, tareas) es la parte del producto donde
el modelo puede dar más valor… y donde más puede fallar. `FoundationModels` no está
disponible en todo dispositivo: `SystemLanguageModel.default.availability` devuelve
`deviceNotEligible`, `appleIntelligenceNotEnabled` o `modelNotReady`. Un `guardrailViolation`
también puede aparecer en cualquier llamada.

## Decisión

El modelo propone; nunca bloquea. Hay dos implementaciones de `NoteEnricher`:

1. `OnDeviceNoteEnricher` — actor que usa `FoundationModels` con un `@Generable`
   `NoteEnrichmentDraft`. Usa `streamResponse` y proyecta cada `Snapshot` a
   `EnrichmentProgress`, de modo que la UI ve el título aparecer antes de que termine el
   resto.
2. `RuleBasedNoteEnricher` — struct determinista, sin modelo ni descarga. Deriva título
   (primera frase sin fillers, cortada en frontera de palabra), resumen (primeras dos
   frases), tags (los `#tag` dichos más los sugeridos) y tareas (oraciones con señales de
   compromiso: "hay que", "tengo que", "necesito", "I need to").

`EnrichTranscript` (Domain) es quien decide: si el enriquecedor lanza cualquier error, cae
al rule-based y la nota se guarda igual. `RuleBasedNoteEnricher.availability` es siempre
`.available`: es el piso del feature, no un último recurso.

Ambas implementaciones emiten más de un paso de progreso y el último lleva `isFinal: true`,
así la UI ejercita el mismo camino progresivo en los dos casos.

## Reglas del prompt

Se le da al modelo reglas explícitas, no sólo una tarea: no inventar contenido, mantener el
idioma del transcript, partir en párrafos, y `actionItems` vacío es una respuesta correcta y
esperada en la mayoría de las notas. Un action item inventado es peor que uno ausente.

## Consecuencias

- La app nunca queda sin función de enriquecimiento: funciona en el iPad viejo, en un
  simulador y en un dispositivo sin Apple Intelligence.
- Un fallo del modelo es invisible para el usuario salvo por el badge "AI edited", que
  distingue una nota enriquecida por IA de una enriquecida por reglas.
- `AIAvailability` mapea las razones de FoundationModels a las del dominio
  (`AIUnavailableReason`), para que la UI no dependa del framework.

## Ver también

- [[Capa de datos]]
- [[El vault markdown es la fuente de verdad]]
