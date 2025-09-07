import SwiftUI

struct MeditationsHomeView: View {
    private let meditations: [MeditationMeta] = [
        MeditationMeta(title: "CALM", folder: "audio/calming", subtitle: "Inara", imageName: "calming"),
        MeditationMeta(title: "FOCUS", folder: "audio/focus", subtitle: "Ikaro", imageName: "focus"),
        MeditationMeta(title: "COMPASSION", folder: "audio/compassion", subtitle: "528 Hertz", imageName: "compassion"),
        MeditationMeta(title: "SELF-AWARENESS", folder: "audio/selfawareness", subtitle: "Arbol del Tule", imageName: "selfawareness")
    ]
    @State private var selected: MeditationMeta? = nil
    @State private var isExpanded: Bool = false
    @Namespace private var cardNamespace

    // Animation constants
    private let openSpring = Animation.spring(response: 0.6, dampingFraction: 0.85, blendDuration: 0.2)
    private let closeSpring = Animation.spring(response: 0.6, dampingFraction: 0.85)
    private let fadeDuration: Double = 0.6
    private var fadeAnimation: Animation { .easeOut(duration: fadeDuration) }
    private let deselectDelay: Double = 0.30

    var body: some View {
        // Main content
        ZStack {
    
            VStack() {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 80)
                    .padding(.top)
                ForEach(meditations, id: \.id) { item in
                    let isActive = (selected?.id == item.id)

                    Button {
                        withAnimation(openSpring) {
                            selected = item
                            isExpanded = true
                        }
                    } label: {
                        MeditationCard(
                            title: item.title,
                            subtitle: item.subtitle,
                            imageName: item.imageName,
                            id: item.id,
                            ns: cardNamespace
                        )
                        
                    }
                    .buttonStyle(.plain)
                    .opacity(isActive ? 0 : 1)           // keep layout; just not visible
                    .allowsHitTesting(!isActive)         // avoid taps leaking
                }
            }
            .padding(.horizontal, 16)
            .opacity(isExpanded ? 0 : 1)
            .animation(fadeAnimation, value: isExpanded)
            }
            .disabled(isExpanded)
 
            
          //expanded card
        if let current = selected {
                MeditationDetailView(meta: current, ns: cardNamespace) {
                    withAnimation(closeSpring) {
                        isExpanded = false
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + deselectDelay) {
                        withAnimation(closeSpring) {
                            selected = nil
                        }
                    }
                }
                .zIndex(1)
            }
        }
    
    }
    
    struct MeditationMeta: Identifiable {
        let id = UUID()
        let title: String
        let folder: String
        let subtitle: String
        let imageName: String
    }
    
#Preview {
    ContentView()
}
