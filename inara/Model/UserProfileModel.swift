//
//  UserProfile.swift
//  inara
//
//  Created by Oscar von Hauske on 1/4/26.
//

import Foundation


struct UserProfileModel: Identifiable, Codable {
    var id: String
    var name: String
    var email: String
    var lastMeditationDate: Date?

    init(id: String = "", name: String = "", email: String = "", lastMeditationDate: Date? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.lastMeditationDate = lastMeditationDate
    }
}
