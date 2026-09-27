//
//  SIgnInView.swift
//  NoteSmart
//
//  Created by Norman Sánchez on 26/09/26.
//

import SwiftUI
import Combine

struct SignInView: View {
    
    @StateObject var viewModel: SignInViewModel
    
    init(viewModel: SignInViewModel) {
        self.viewModel = @State(wrappedValue: _viewModel)
    }
    
    var body: some View {
        VStack {
            TextField(<#T##titleKey: LocalizedStringKey##LocalizedStringKey#>, text: <#T##Binding<String>#>)
        }
    }
}
