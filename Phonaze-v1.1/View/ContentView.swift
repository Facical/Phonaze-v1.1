import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @EnvironmentObject var gameState: GameState
    @State private var navStackID = UUID()
    
    var body: some View {
        NavigationStack {
            StartView()
        }
        .id(navStackID)
        .onChange(of: gameState.shouldReturnToStart) { shouldReturn in
            if shouldReturn {
                navStackID = UUID() // stack 전체 리셋
                gameState.shouldReturnToStart = false
            }
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
        .environmentObject(ConnectivityManager())
        .environmentObject(GameState())
}
