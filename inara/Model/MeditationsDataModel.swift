//
//  MeditationsDataModel.swift
//  inara
//
//  Created by Oscar von Hauske on 12/21/25.
//

import Foundation

struct MeditationDataModel: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let audiosrc: String
    let subtitle: String
    let imageName: String
}
