//
//  LogoView.swift
//  inara
//
//  Created by Oscar von Hauske on 12/21/25.
//

import SwiftUI

struct LogoView: View {
    var body: some View {
        Image("logo")
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: 120, height: 80)
            .foregroundColor(AppColors.tulum)
            .padding(.top)
    }
}

#Preview {
    LogoView()
}
