import SwiftUI

struct MeditationCard: View {
    let title: String
    let subtitle: String
    let imageName: String
    let id: UUID
    let ns: Namespace.ID
    
    var body: some View {
        
        VStack(spacing: 4) {
            Image(imageName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: 48)
                .foregroundColor(AppColors.tulum)
                .matchedGeometryEffect(id: "image.\(id)", in: ns)
                        
            Text(title)
                .titleStyle()
                .multilineTextAlignment(.center)
                .matchedGeometryEffect(id: "title.\(id)", in: ns)
            
            Text(subtitle)
                .subtitleStyle()
                .multilineTextAlignment(.center)
                .matchedGeometryEffect(id: "subtitle.\(id)", in: ns)

        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(AppColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(AppColors.outline, lineWidth: 1)
                )
                .matchedGeometryEffect(id: "card.\(id)", in: ns, isSource: true)
        )

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
