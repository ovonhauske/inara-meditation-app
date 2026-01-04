import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct UserProfile: Identifiable, Codable {
    var id: String
    var name: String
    var email: String

    init(id: String = "", name: String = "", email: String = "") {
        self.id = id
        self.name = name
        self.email = email
    }
}

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var profile: UserProfile = .init()
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()

    func loadProfile() async {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.errorMessage = "Not signed in."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            if let data = snapshot.data() {
                let name = data["name"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                self.profile = UserProfile(id: uid, name: name, email: email)
            } else {
                self.errorMessage = "No profile found."
            }
        } catch {
            self.errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
