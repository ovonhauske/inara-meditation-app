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
    
    var body: some View {
        // Keep everything inside a single ZStack; animate card → player using matchedGeometryEffect
        ZStack {
            // Scrim to block taps and dim background while expanded
           
            // Background content (disabled while expanded to prevent tap leaks)
            VStack() {
                Image("logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 80)
                    .padding(.top)
                                ForEach(meditations) { item in
                    if selected?.id == item.id && isExpanded {
                        // Remove source from hierarchy during expansion to avoid duplicate sources
                        Color.surface
                            .frame(width: 350, height: 150)
                    } else {
                        Button(action: {
                            selected = item
                            withAnimation(.spring(response: 0.45, dampingFraction: 0.85, blendDuration: 0.2)) {
                                isExpanded = true
                            }
                        }) {
                            MeditationCard(
                                title: item.title,
                                subtitle: item.subtitle,
                                imageName: item.imageName,
                                id: item.id,
                                ns: cardNamespace)                                
                        }
                        .buttonStyle(.plain)
                        .opacity(selected?.id == item.id && isExpanded ? 0 : 1) // hide instead of removing
                    }
                }
                }
            }
            .disabled(isExpanded)
 
            
          //expanded card
            if let current = selected {
                ZStack(alignment: .topTrailing) {
                    Button(action: {
                        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                            isExpanded = false
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                            selected = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(16)
                    }
                    
                    // Expanded content hosts the player with a matched header
                    VStack(spacing: 16) {
                        Image(current.imageName)
                            .renderingMode(.template)
                            .resizable()
                            .scaledToFit()
                            .foregroundColor(Color("accent"))
                            .frame(height: 64)
                            .matchedGeometryEffect(id: "image.\(current.id)", in: cardNamespace, isSource: false)

                        Text(current.title)
                            .font(.title3.weight(.semibold))

                        Text(current.subtitle)
                            .font(.callout)

                        // Player and bottom actions – fade/scale in
                        MeditationPlayerView(title: current.title, folder: current.folder)
                            .frame(maxHeight: .infinity)
                    }
                    .matchedGeometryEffect(id: "image.\(current.id)", in: cardNamespace, isSource: false)

                    .solidCardStyle(fill:Color.green, outline: AppColors.outline)
                    .padding(.top, 24)
                }
                .background(Color.red)
                .zIndex(1)
                .transition(.identity) // rely purely on matched geometry for morph
                
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
    
