//
//  ContentView.swift
//  RAG APPLICATION
//
//  Created by Abdul Samad Gilal on 13/06/2026.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var rag = RAGService()

    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                }

            DocumentsView()
                .tabItem {
                    Label("Documents", systemImage: "doc.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .environmentObject(rag)
    }
}

#Preview {
    ContentView()
}
