import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack{
            Color("surface").ignoresSafeArea()
            MeditationsHomeView()
        }
    }
}

#Preview {
    ContentView()
}

// Home view moved to MeditationsHomeView.swift
