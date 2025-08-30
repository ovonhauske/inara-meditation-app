import SwiftUI

struct MeditationCard: View {
    let title: String
    let subtitle: String
    let imageName: String
    let id: UUID
    let ns: Namespace.ID?   // ← optional, default nil
    
    init(title: String, subtitle: String, imageName: String, id: UUID, ns: Namespace.ID? = nil) {
           self.title = title
           self.subtitle = subtitle
           self.imageName = imageName
           self.id = id
           self.ns = ns
       }
    
    var body: some View {
        VStack(spacing: 12) {
            Image(imageName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: 48)
                .foregroundColor(Color("accent"))
                .applyMatch(ns, key: "image", id: id)

            Spacer(minLength: 0)

            Text(title)
                .font(.body)
                .foregroundColor(Color("accent"))
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.caption)
                .foregroundColor(Color("accent"))
                .multilineTextAlignment(.center)
        }
        .padding(24)
    }
}

private extension View {
    @ViewBuilder
    func applyMatch(_ ns: Namespace.ID?, key: String, id: UUID) -> some View {
        if let ns {
            self.matchedGeometryEffect(id: "\(key).\(id)", in: ns)
        } else {
            self
        }
    }
}

#Preview {
    CardPreview()
}

private struct CardPreview: View {
    @Namespace var ns
    private let demoID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    var body: some View {
        MeditationCard(
            title: "Inara",
            subtitle: "Calming",
            imageName: "calming",
            id: demoID,
            ns: ns                      // now in scope
        )
        .frame(width: 350, height: 150)
        .solidCardStyle(fill: AppColors.background, outline: AppColors.outline)
        .padding()
    }
}
