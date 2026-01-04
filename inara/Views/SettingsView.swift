//
//  settings.swift
//  inara
//
//  Created by Oscar von Hauske on 1/3/26.
//

import SwiftUI

struct SettingsView: View {
    
    var body: some View {
        ZStack{
            AppColors.surface.ignoresSafeArea()
            List{
                Group{
                    HStack {
                        Text("Name")
                        Spacer()
                        Text("Oscar")
                    }
                    HStack {
                        Text("Email")
                        Spacer()
                        Text("ovh@mac.com")
                    }                }
                .listRowBackground(Color.clear)

                Group{
                    Text("Send Feedback")
                }
                .listRowBackground(Color.clear)

                Group{
                    Text("Sign Out")
                    Text("Delete accout")
                }
                .listRowBackground(Color.clear)

                Group{
                    Text("Learn about scent & sound")
                    Text("About Inara")
                    Text("Terms of service")
                    Text("Privacy")
                }
                .listRowBackground(Color.clear)

            }
            .listStyle(.plain)
        }
    }
}

#Preview {
    SettingsView()
}
