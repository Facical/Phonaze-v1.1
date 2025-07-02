//
//  HomeView.swift
//  Phonaze
//
//  Created by 강형준 on 3/18/25.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    @EnvironmentObject var gameState: GameState
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Phonaze 게임 메뉴")
                .font(.title).bold()
            // Select 게임으로 이동
            NavigationLink(destination: SelectView()) {
                Label("패널 선택 게임 (Select)", systemImage: "square.grid.4x3.fill")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.2))
                    .cornerRadius(10)
            }
            // Scroll 게임으로 이동
            NavigationLink(destination: ScrollViewGame()) {
                Label("숫자 찾기 게임 (Scroll)", systemImage: "number.circle")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.green.opacity(0.2))
                    .cornerRadius(10)
            }
        }
        .padding(40)
        .navigationTitle("🕹 Home")  // NavigationStack 상단에 제목 표시
        .onAppear {
            // 홈 화면이 나타날 때 게임 상태 초기화
            gameState.currentMode = .none
            gameState.targetCoord = nil
            gameState.targetNumber = nil
        }
    }
}
