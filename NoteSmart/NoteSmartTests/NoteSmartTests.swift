//
//  NoteSmartTests.swift
//  NoteSmartTests
//
//  Created by Norman Sánchez on 26/09/26.
//

import DSOrganisms
import Foundation
import NoteSmartDomain
import Testing
@testable import NoteSmart

@Suite("Nota → tarjeta")
struct NoteCardModelTests {

    private func makeNote(
        title: String = "Weekly sync",
        body: String = "",
        tags: [String] = [],
        audio: TimeInterval? = 42,
        source: NoteSource = .voice,
        enriched: Bool = false
    ) -> Note {
        Note(
            folder: VaultPath(),
            fileName: "weekly-sync.md",
            frontmatter: NoteFrontmatter(
                title: title,
                created: Date(timeIntervalSince1970: 1_700_000_000),
                modified: Date(timeIntervalSince1970: 1_700_003_600),
                tags: tags.compactMap(VaultTag.init),
                audio: audio.map { AudioRef(fileName: "a.m4a", duration: $0) },
                source: source,
                enriched: enriched
            ),
            body: body
        )
    }

    @Test("Mapea los datos visibles de una nota")
    func mapsNote() {
        let card = NoteCardModel(
            makeNote(
                title: "Weekly sync",
                tags: ["work", "planning"],
                audio: 95,
                enriched: true
            )
        )

        #expect(card.title == "Weekly sync")
        #expect(card.duration == 95)
        #expect(card.tags == ["#work", "#planning"])
        #expect(card.badges.map(\.text) == ["IA", "Voz"])
    }

    @Test("Una nota sin audio no muestra duración")
    func noAudioNoDuration() {
        #expect(NoteCardModel(makeNote(audio: nil)).duration == nil)
    }

    @Test("El preview toma la prosa y descarta resumen, secciones y transcript")
    func previewSkipsNoise() {
        let body = """
        > Resumen de una línea.

        Hablamos del roadmap y del hiring.

        ## Action items

        - [ ] Mandar el presupuesto
        - [x] Cerrar el hiring

        ## Transcript

        - [00:12] esto es el transcript
        """
        let preview = NoteCardModel(makeNote(body: body)).preview

        #expect(preview == "Hablamos del roadmap y del hiring.")
    }

    @Test("El preview cae al transcript cuando no hay prosa")
    func previewFallsBackToTranscript() {
        var note = makeNote(body: "## Transcript\n\n- [00:00] hola")
        note.transcript = [
            TranscriptSegment(text: "hola", range: TimeRange(start: 0, end: 1))
        ]

        #expect(NoteCardModel(note).preview == "hola")
    }

    @Test("Cuenta sólo las tareas pendientes")
    func countsPendingTasks() {
        let body = """
        - [ ] una
        - [x] dos
        * [ ] tres
        - sin checkbox
        """
        let card = NoteCardModel(makeNote(body: body))

        #expect(card.badges.map(\.text) == ["Voz", "2"])
    }

    @Test("La procedencia de la nota se refleja en un badge")
    func sourceBadge() {
        #expect(NoteCardModel(makeNote(source: .manual)).badges.map(\.text) == ["Texto"])
        #expect(NoteCardModel(makeNote(source: .imported)).badges.map(\.text) == ["Importada"])
    }
}

@Suite("Cuerpo de la nota")
struct NoteBodyTests {

    @Test("La prosa termina donde empieza la primera sección generada")
    func cutsAtGeneratedSection() {
        let body = """
        Resumen

        ## Action items

        - [ ] x

        ## Transcript

        - [00:00] hola
        """
        #expect(NoteBody.prose(from: body) == "Resumen")
    }

    @Test("Un encabezado del usuario no corta la prosa del editor")
    func keepsUserHeadings() {
        let body = """
        ## Reflexión

        Esto sí es contenido.

        ## Transcript

        - [00:00] hola
        """
        #expect(NoteBody.prose(from: body) == "## Reflexión\n\nEsto sí es contenido.")
    }

    @Test("Un teaser corta en cualquier encabezado")
    func teaserCutsAtAnyHeading() {
        let body = "## Reflexión\n\nEsto es contenido."
        #expect(NoteBody.prose(from: body, cuttingAtAnyHeading: true) == "")
    }

    @Test("Un cuerpo sin secciones es sólo prosa")
    func noGeneratedSections() {
        #expect(NoteBody.prose(from: "sólo prosa") == "sólo prosa")
        #expect(NoteBody.prose(from: "## Transcript\n\n- [00:00] hola") == "")
        #expect(NoteBody.prose(from: "") == "")
    }
}
