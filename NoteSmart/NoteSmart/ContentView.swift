//
//  ContentView.swift
//  NoteSmart
//
//  Created by Norman Sánchez on 26/09/26.
//

import SwiftUI
import SwiftData

struct ContentView: View {

    var body: some View {
        WelcomeView()
    }

}


#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}
