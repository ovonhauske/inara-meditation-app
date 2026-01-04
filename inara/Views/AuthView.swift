//
//  AuthView.swift
//  inara
//
//  Created by Oscar von Hauske on 1/1/26.
//

import SwiftUI
import AuthenticationServices
import CryptoKit
import FirebaseAuth
import FirebaseFirestore


struct AuthView: View {
    @State private var currentNonce: String? = nil
    @State private var showSignInError = false
    @Environment(\.colorScheme) private var colorScheme
    var onSignIn: (() -> Void)? = nil
    var body: some View {
        VStack{
            LogoView()
            OnboardingHScroll()
            SignInWithAppleButton(.signIn) { request in
                let nonce = randomNonceString()
                currentNonce = nonce
                request.requestedScopes = [.fullName, .email]
                request.nonce = sha256(nonce)
            } onCompletion: { result in
                switch result {
                case .success(let authorization):
                    guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                        print("Firebase Apple Sign-In: Missing Apple ID credential")
                        return
                    }

                    guard let identityTokenData = appleIDCredential.identityToken,
                          let identityToken = String(data: identityTokenData, encoding: .utf8) else {
                        print("Firebase Apple Sign-In: Unable to fetch identity token")
                        return
                    }

                    guard let nonce = currentNonce else {
                        print("Firebase Apple Sign-In: Missing current nonce")
                        return
                    }

                    let credential = OAuthProvider.appleCredential(
                        withIDToken: identityToken,
                        rawNonce: nonce,
                        fullName: appleIDCredential.fullName
                    )

                    Task { @MainActor in
                        do {
                            let authResult = try await Auth.auth().signIn(with: credential)
                            let uid = authResult.user.uid

                            // Build display name if Apple provided it (first sign-in only)
                            var displayName: String? = nil
                            if let fullName = appleIDCredential.fullName {
                                let name = [fullName.givenName, fullName.familyName]
                                    .compactMap { $0 }
                                    .joined(separator: " ")
                                if !name.isEmpty { displayName = name }
                            }

                            let email = appleIDCredential.email

                            // Persist to Firestore
                            try? await ProfileService.upsertProfile(uid: uid,
                                                                    displayName: displayName,
                                                                    email: email)

                            // Optionally update Firebase Auth displayName for convenience
                            if let displayName {
                                let change = authResult.user.createProfileChangeRequest()
                                change.displayName = displayName
                                try? await change.commitChanges()
                            }

                            print("Firebase Apple Sign-In: Success for uid \(uid)")
                            onSignIn?()
                        } catch {
                            print("Firebase Apple Sign-In: Firebase error \(error.localizedDescription)")
                            showSignInError = true
                        }
                    }
                case .failure(let error):
                    print("Could not authenticate: \(error.localizedDescription)")
                    showSignInError = true
                }
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .black : .white)
            .frame(maxWidth: .infinity, maxHeight: 50)
            .cornerRadius(99)
            .padding(.top, 8)
            .padding(.horizontal, 40)
            .alert("Sign in failed", isPresented: $showSignInError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Please try again later")
            }
            
        }
    }
}

#Preview {
    ZStack{
        AppColors.surface.ignoresSafeArea()
        AuthView()
    }
}

private func sha256(_ input: String) -> String {
    let inputData = Data(input.utf8)
    let hashed = SHA256.hash(data: inputData)
    return hashed.compactMap { String(format: "%02x", $0) }.joined()
}
private func randomNonceString(length: Int = 32) -> String {
    precondition(length > 0)
    let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
    var result = ""
    var remainingLength = length

    while remainingLength > 0 {
        var randoms = [UInt8](repeating: 0, count: 16)
        let errorCode = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
        if errorCode != errSecSuccess {
            fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
        }
        randoms.forEach { random in
            if remainingLength == 0 { return }
            if random < charset.count {
                result.append(charset[Int(random)])
                remainingLength -= 1
            }
        }
    }
    return result
}

