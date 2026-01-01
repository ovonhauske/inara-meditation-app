//
//  OnboardingHScroll.swift
//  inara
//
//  Created by Oscar von Hauske on 12/31/25.
//

import SwiftUI

struct OnboardingHScrollCArd: View {
    var title:String = "Improve your state of mind"
    var subtitle: String = "Meditations to get calm, confidence. Be more balanced, or open your heart."
    
    var body: some View {
        VStack(spacing: 14) {
            Image("hscroll1")
                .frame(width: 200,height: 200)
            
            VStack(spacing:4) {
                Text(title)
                    .titleStyle()
                    .multilineTextAlignment(.center)
            
            Text(subtitle)
                .subtitleStyle()
                .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    OnboardingHScrollCArd(title: "Yoyoyoyoy")
}
