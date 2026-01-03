import SwiftUI

struct ContentView: View {
    @State private var isAuthenticated = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.surface.ignoresSafeArea()
                if isAuthenticated {
                    MeditationsListView()
                        .transition(.opacity)
                } else {
                    AuthView(onSignIn: {
                        withAnimation(.easeInOut(duration: 1)) {
                            isAuthenticated = true
                        }
                    })
                    .background(Color.clear)
                    .transition(.opacity)
                }
            }
            .animation(AppAnimation.spring, value: isAuthenticated)
        }
    }
}

#Preview {
    ContentView()
}
