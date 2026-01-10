//
//  inaraApp.swift
//  inara
//
//  Created by Oscar von Hauske on 8/5/25.
//

import SwiftUI
import SwiftData
import FirebaseCore

@main
struct inaraApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ZStack {

                ContentView()
            }
        }
        .modelContainer(for: [SomaProfile.self, SomaticInsight.self])
    }
}
