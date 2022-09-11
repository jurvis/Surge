//
//  SurgeApp.swift
//  Shared
//
//  Created by Jurvis on 9/4/22.
//

import SwiftUI
import Lightning

@main
struct SurgeApp: App {    
    var body: some Scene {
        WindowGroup {
            HomeView(viewModel: HomeViewModel())
                .onAppear {
                    Task {
                        try await LightningNodeService.shared.start()
                    }
                }
        }
    }
}
