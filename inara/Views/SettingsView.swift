//
//  settings.swift
//  inara
//
//  Created by Oscar von Hauske on 1/3/26.
//

import SwiftUI

struct SettingsView: View {
    @StateObject var viewModel: SettingsViewModel = SettingsViewModel()
    @State private var showingDeleteAlert = false
    @State private var safariUrl: IdentifiableURL?
    
    @Environment(\.openURL) var openURL

    var body: some View {
        ZStack{
            AppColors.surface.ignoresSafeArea()
            VStack {
                Image("hscroll1")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150, height: 150)
                if let date = viewModel.profile.lastMeditationDate {
                    Text("Last meditation: \(date.formatted(.relative(presentation: .named)))")
                        .font(.caption)
                        .foregroundStyle(AppColors.tulum)
                } else {
                    Text("Last meditation: Never")
                        .font(.caption)
                        .foregroundStyle(AppColors.tulum)
                }
                List{
                    Group{
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(viewModel.profile.name.isEmpty ? "—" : viewModel.profile.name)
                        }
                        HStack {
                            Text("Email")
                            Spacer()
                            Text(viewModel.profile.email.isEmpty ? "—" : viewModel.profile.email)
                        }                }
                    .listRowBackground(Color.clear)
                    
                    Group{
                        Button("Send Feedback") {
                            var components = URLComponents()
                            components.scheme = "mailto"
                            components.path = "hello@inarasense.com"
                            components.queryItems = [
                                URLQueryItem(name: "subject", value: "[Feedback] \(Date().formatted())")
                            ]

                            if let url = components.url {
                                openURL(url)
                            }
                        }
                        .foregroundStyle(Color.primary)
                    }
                    .listRowBackground(Color.clear)
                    
                    Group{
                        Button("Learn about scent & sound") {
                            safariUrl = IdentifiableURL(url: URL(string: "https://www.inarasense.com/learn")!)
                        }
                        .foregroundStyle(Color.primary)
                        
                        Button("About Inara") {
                            safariUrl = IdentifiableURL(url: URL(string: "https://www.inarasense.com/about")!)
                        }
                        .foregroundStyle(Color.primary)
                        
                        Text("Terms of service")
                        Text("Privacy")
                    }
                    .listRowBackground(Color.clear)
                    
                    Group{
                        Button("Sign Out") {
                            self.viewModel.signOut()
                        }
                        .foregroundStyle(Color.primary)
                        
                        Button("Delete Account") {
                            showingDeleteAlert = true
                        }
                        .foregroundStyle(Color.red)
                    }
                    .listRowBackground(Color.clear)
                    
                }
                .listStyle(.plain)
                .task {
                    await self.viewModel.loadProfile()
                }
                .alert("Delete Account", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        Task { await self.viewModel.deleteAccount() }
                    }
                } message: {
                    Text("Are you sure you want to delete your account? This action cannot be undone.")
                }
                .sheet(item: $safariUrl) { wrapper in
                    SafariView(url: wrapper.url)
                        .ignoresSafeArea()
                }
            }
        }
    }
}

struct IdentifiableURL: Identifiable {
    let id = UUID()
    let url: URL
}

#Preview {
    SettingsView()
}
