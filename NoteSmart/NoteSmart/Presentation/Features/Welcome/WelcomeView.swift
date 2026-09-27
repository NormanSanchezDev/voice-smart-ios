//
//  WelcomeView.swift
//  NoteSmart
//
//  Created by Norman Sánchez on 26/09/26.
//

import SwiftUI

struct WelcomeView: View {
    var body: some View {
        VStack {
            Text("Welcome to Smart Notes")
            
            Button(action: {
                // do something
            }, label: {
                Text("Let's begin")
            })
        }
    }
}

#Preview {
    WelcomeView()
}
