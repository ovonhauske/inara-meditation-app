//
//  MeditationViewModel.swift
//  inara
//
//  Created by Oscar von Hauske on 12/27/25.
//

import Foundation

@Observable
class MeditationViewModel {
    var meditations: [MeditationDataModel] = [
        MeditationDataModel(
            title: "Calm",
            audiosrc: "audio/calming",
            subtitle: "Inara",
            imageName: "calming"
        ),
        MeditationDataModel(
            title: "Confidence",
            audiosrc: "audio/focus",
            subtitle: "Ikaro",
            imageName: "focus"
        ),
        MeditationDataModel(
            title: "Open Heart",
            audiosrc: "audio/compassion",
            subtitle: "528 Hertz",
            imageName: "compassion"
        ),
        MeditationDataModel(
            title: "Balance",
            audiosrc: "audio/selfawareness",
            subtitle: "Arbol del Tule",
            imageName: "selfawareness"
        )
    ]
}
