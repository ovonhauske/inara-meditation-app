import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

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

    // Optional: live updates with a listener instead of one-time fetch
    func startListening() {
        guard let uid = Auth.auth().currentUser?.uid else {
            self.errorMessage = "Not signed in."
            return
        }
        db.collection("users").document(uid).addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                Task { @MainActor in self.errorMessage = error.localizedDescription }
                return
            }
            guard let data = snapshot?.data() else { return }
            let name = data["name"] as? String ?? ""
            let email = data["email"] as? String ?? ""
            Task { @MainActor in
                self.profile = UserProfile(id: uid, name: name, email: email)
            }
        }
    }
}