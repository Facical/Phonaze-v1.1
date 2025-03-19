//
//  SelectView.swift
//  Phonaze
//
//  Created by 강형준 on 3/18/25.
//

import SwiftUI

struct SelectView: View {
    @EnvironmentObject var gameState: GameState
    
    // 4x4 패널 그리드 레이아웃 설정 (GridItems 이용)
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 4)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("패널 선택 게임").font(.title2).bold()
            // 4x4 Grid 형태로 패널 배치
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(0..<16) { index in
                    let row = index / 4
                    let col = index % 4
                    // 패널 한 칸 (정답 좌표와 일치하면 파란색으로 강조)
                    Rectangle()
                        .fill(panelColor(row: row, col: col))
                        .frame(height: 60)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Color.black.opacity(0.2), lineWidth: 1)
                        )
                        .onTapGesture {
                            handleTap(row: row, col: col)
                        }
                }
            }
            .padding()
            
            // 최근 결과 표시 (optional)
            if let time = gameState.lastSelectTime {
                Text(String(format: "✅ 선택 완료: %.2f초 소요", time))
                    .foregroundStyle(.secondary)
            } else {
                Text("올바른 패널을 선택하세요")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(30)
        .onAppear {
            // 화면이 나타났을 때, 만약 GameState에 목표 좌표가 없다면 안내
            if gameState.targetCoord == nil {
                print("경고: iPhone으로부터 좌표를 아직 받지 못함.")
            }
        }
    }
    
    /// 패널 색상을 결정 (목표 패널이면 파란색, 아니면 회색)
    private func panelColor(row: Int, col: Int) -> Color {
        if let target = gameState.targetCoord, target.x == row && target.y == col {
            return Color.blue  // 정답 패널은 파란색
        } else {
            return Color.gray.opacity(0.3)  // 기타 패널은 연한 회색
        }
    }
    
    /// 패널 탭 처리
    private func handleTap(row: Int, col: Int) {
        guard let target = gameState.targetCoord else { return }
        if row == target.x && col == target.y {
            // 올바른 패널 선택
            gameState.completeSelectGame()  // 시간 측정 완료 처리
        } else {
            // 잘못된 패널 선택 (필요 시 피드백 구현 가능)
            print("오답 패널 선택: (\(row), \(col))")
        }
    }
}
