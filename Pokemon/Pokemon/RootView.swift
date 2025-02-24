//
//  RootView.swift
//  Pokemon
//
//  Created by Peier Chen on 2025-02-24.
//
import SwiftUI

struct RootView: View {
    @State private var destinations = [PokeDestination]()
    var body: some View {
        NavigationStack(path: $destinations) {
            ContentView()
        }
    }
}

