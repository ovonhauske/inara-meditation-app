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
        
        VStack(spacing: 4) {
            Image(imageName)
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(height: 48)
                .foregroundColor(AppColors.tulum)
                .matchedGeometryEffect(id: "image.\(id)", in: ns)
                        
            Text(title)
                .font(.body)
                .foregroundColor(AppColors.tulum)
                .multilineTextAlignment(.center)
                .textCase(.uppercase)
                .kerning(2)
                
            
            
            Text(subtitle)
                .font(.caption)
                .foregroundColor(AppColors.tulum)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.surface)
        .cornerRadius(30)
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .inset(by: 1) // optional: pull the border slightly inward
                .stroke(AppColors.outline, lineWidth: 1)
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
