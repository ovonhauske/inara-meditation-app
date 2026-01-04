//
//  ProfileService.swift
//  inara
//
//  Created by Assistant on 1/3/26.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

struct UserProfile: Codable {
    let uid: String
    var displayName: String?
    var email: String?
    var updatedAt: Date?
    var lastMeditationDate: Date?
}

enum ProfileService {
    static let db = Firestore.firestore()

    /// Create or update a user's profile document in Firestore.
    static func upsertProfile(uid: String, displayName: String?, email: String?, lastMeditationDate: Date? = nil) async throws {
        var payload: [String: Any] = [
            "uid": uid,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let displayName, !displayName.isEmpty {
            payload["displayName"] = displayName
        }
        if let email, !email.isEmpty {
            payload["email"] = email
        }
        if let lastMeditationDate {
            payload["lastMeditationDate"] = lastMeditationDate
        }
        try await db.collection("users").document(uid).setData(payload, merge: true)
    }

    /// Fetch a user's profile document from Firestore.
    static func fetchProfile(uid: String) async throws -> UserProfile? {
        let doc = try await db.collection("users").document(uid).getDocument()
        guard let data = doc.data() else { return nil }
        return UserProfile(
            uid: uid,
            displayName: data["displayName"] as? String,
            email: data["email"] as? String,
            updatedAt: (data["updatedAt"] as? Timestamp)?.dateValue(),
            lastMeditationDate: (data["lastMeditationDate"] as? Timestamp)?.dateValue()
        )
    }
    
    /// Update only the last meditation date for the current user
    static func updateLastMeditationDate() async throws {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let payload: [String: Any] = [
            "lastMeditationDate": FieldValue.serverTimestamp(),
            "updatedAt": FieldValue.serverTimestamp()
        ]
        try await db.collection("users").document(uid).updateData(payload)
    }
}
