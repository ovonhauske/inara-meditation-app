import SwiftUI

struct MeditationCard: View {
    let title: String
    let subtitle: String
    let imageName: String
    let id: UUID
    let ns: Namespace.ID
    
    init(title: String, subtitle: String, imageName: String, id: UUID, ns: Namespace.ID) {
           self.title = title
           self.subtitle = subtitle
           self.imageName = imageName
           self.id = id
           self.ns = ns
       }
    
    var body: some View {
        ZStack{
            let shape = RoundedRectangle(cornerRadius: 30, style: .continuous)
            shape
                .fill(AppColors.surface)                // opaque background (no material)
                .overlay(shape.stroke(AppColors.outline, lineWidth: 1))
                .matchedGeometryEffect(id: "card.\(id)", in: ns)

            VStack(spacing: 12) {
                Image(imageName)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 48)
                    .foregroundColor(AppColors.tulum)
                    .matchedGeometryEffect(id: "image.\(id)", in: ns)
                
                Spacer(minLength: 0)
                
                Text(title)
                    .font(.body)
                    .foregroundColor(AppColors.tulum)
                    .multilineTextAlignment(.center)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(AppColors.tulum)
                    .multilineTextAlignment(.center)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity)


    }

}



#Preview {
    struct CardPreview: View {
        @Namespace var ns
        var body: some View {
            MeditationCard(
                title: "Inara",
                subtitle: "Calming",
                imageName: "calming",
                id: UUID(),
                ns: ns
            )
            .padding()
        }
    }
    return CardPreview()
}
