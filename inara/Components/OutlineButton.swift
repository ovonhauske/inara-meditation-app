//
//  OutlineButton.swift
//  inara
//
//  Created by Oscar von Hauske on 12/31/25.
//

import SwiftUI

struct OutlineButton: View {
    var text: String
    var icon: String
    var url: URL? = nil
    var action: (() -> Void)? = nil
    
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Button {
            if let url {
                openURL(url)
            } else {
                print("Button tapped")
                action?()
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(text)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
        }
        .font(.body)
        .foregroundStyle(AppColors.tulum)
        .buttonStyle(.bordered)
        .tint(AppColors.transparent)
        .background(
            RoundedRectangle(cornerRadius: 99, style: .continuous)
                .stroke(AppColors.outline, lineWidth: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 99, style: .continuous))
        .contentShape(RoundedRectangle(cornerRadius: 99, style: .continuous))
    }
}

#Preview {
    VStack(spacing: 16) {
        OutlineButton(text:"Continue with Apple", icon: "apple.logo") {
            print("Tapped Apple sign-in")
        }
        OutlineButton(text:"Shop", icon: "cart", url: URL(string: "https://www.inarasense.com/shop"))
    }
    .padding()
}
