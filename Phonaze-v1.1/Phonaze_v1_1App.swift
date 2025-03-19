//
//  Phonaze_v1_1App.swift
//  Phonaze-v1.1
//
//  Created by 강형준 on 3/18/25.
//

import SwiftUI

@main
struct Phonaze_v1_1App: App {
    // 환경 객체로 사용할 상태 객체들 초기화
    @StateObject private var gameState = GameState()
    @StateObject private var connectivity = ConnectivityManager()
        
    var body: some Scene {
        WindowGroup {
            // ContentView를 초기 뷰로 표시하고 환경 객체 주입
            ContentView()
                .environmentObject(connectivity)
                .environmentObject(gameState)
                .onAppear {
                    connectivity.setGameState(gameState)
                }
        }
    }
}
