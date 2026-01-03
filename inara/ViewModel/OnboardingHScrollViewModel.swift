//
//  MeditationViewModel.swift
//  inara
//
//  Created by Oscar von Hauske on 12/27/25.
//

import Foundation

@Observable
class OnboardingHScrollViewModel {
    var HScrollCards: [OnboardingHScrollDataModel] = [
        OnboardingHScrollDataModel(
            title: "Improve your state of mind",
            subtitle: "Meditations to get calm, confidence. Be more balanced, or open your heart.",
            imageName: "hscroll1"
        ),
        OnboardingHScrollDataModel(
            title: "IMMERSE IN SOUND",
            subtitle: "Soundscapes designed by world-renowned musicians to alter your nervous system",
            imageName: "hscroll2"
        ),
        OnboardingHScrollDataModel(
            title: "Pair with aN INARA fragrance",
            subtitle: "Meditations to get calm, confidence. Be more balanced, or open your heart.",
            imageName: "hscroll3"

        ),

    ]
}
