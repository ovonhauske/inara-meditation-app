//
//  TextMeditationPrep.swift
//  inara
//
//  Created by Oscar von Hauske on 1/5/26.
//

import SwiftUI

struct TextMeditationPrep: View {
    
    // The sequence of gentle instructions
        let instructions = [
            "Find a posture that feels steady.",
            "Headphones help you go deeper.",
            "Rest the device gently in your hand.",
            "Soften your gaze."
        ]
        
        @State private var index = 0
        @State private var opacity: Double = 0
        @State private var hasFinished = false
        
        // Callback to tell the parent view to start the player
        var onComplete: () -> Void
    
    var body: some View {
        Text("Find a comfortable seat")
        Text("Put your headhpones on")
        
    }
}

#Preview {
    ZStack{
        AppColors.surface.ignoresSafeArea()
        TextMeditationPrep()

    }
    
}
