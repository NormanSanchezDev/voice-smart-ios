//
//  SignInViewModel.swift
//  NoteSmart
//
//  Created by Norman Sánchez on 26/09/26.
//

import Foundation
import Combine

@MainActor
final class SignInViewModel: ObservableObject {
    
    let signInUIState: SignInUIState
    
    init(signInUIState: SignInUIState) {
        self.signInUIState = signInUIState
    }
    
    func doSignIn() {
        
    }
    
}
