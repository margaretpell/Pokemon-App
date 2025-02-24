import SwiftUI

struct RootView: View {
    @State private var destinations = [PokeDestination]()
    var body: some View {
        NavigationStack(path: $destinations) {
            ContentView()
        }
    }
}

