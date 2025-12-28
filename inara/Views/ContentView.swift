import SwiftUI

struct ContentView: View {

    var body: some View {
        ZStack{
            Color("surface").ignoresSafeArea()
            VStack{
                MeditationsList()
            }
            }
    }
}

#Preview {
    ContentView()
}

// Home view moved to MeditationsHomeView.swift
