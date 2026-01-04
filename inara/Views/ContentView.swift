import SwiftUI
import FirebaseAuth

struct ContentView: View {
    enum Phase { case loading, signedIn, signedOut }

    @State private var phase: Phase = .loading
    @State private var authHandle: AuthStateDidChangeListenerHandle?

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.surface.ignoresSafeArea()
                switch phase {
                case .loading:
                    ProgressView()
                case .signedIn:
                    MeditationsListView()
                        .transition(.opacity)
                case .signedOut:
                    AuthView(onSignIn: {
                        withAnimation(.easeInOut(duration: 1)) {
                            phase = .signedIn
                        }
                    })
                    .background(Color.clear)
                    .transition(.opacity)
                }
            }
            // Animate only when transitioning to signed-in UI
            .animation(AppAnimation.spring, value: phase == .signedIn)
        }
        .onAppear {
            // Listen for Firebase auth state changes (including restoration on launch)
            authHandle = Auth.auth().addStateDidChangeListener { _, user in
                withAnimation(.easeInOut) {
                    phase = (user != nil) ? .signedIn : .signedOut
                }
            }
        }
        .onDisappear {
            if let handle = authHandle {
                Auth.auth().removeStateDidChangeListener(handle)
            }
        }
    }
}

#Preview {
    ContentView()
}
