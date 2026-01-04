//
//  UserProfile.swift
//  inara
//
//  Created by Oscar von Hauske on 1/4/26.
//


struct UserProfileModel: Identifiable, Codable {
    var id: String
    var name: String
    var email: String

    init(id: String = "", name: String = "", email: String = "") {
        self.id = id
        self.name = name
        self.email = email
    }
}
