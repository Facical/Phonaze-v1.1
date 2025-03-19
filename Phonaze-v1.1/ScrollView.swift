//
//  ScrollView.swift
//  Phonaze
//
//  Created by 강형준 on 3/18/25.
//

import SwiftUI

struct ScrollViewGame: View {
    @EnvironmentObject var gameState: GameState
    
    // 예시: 1부터 50까지의 숫자 리스트 (필요시 범위 확장 가능)
    private let numbers = Array(1...50)
    
    var body: some View {
        VStack(spacing: 20) {
            Text("숫자 찾기 게임").font(.title2).bold()
            Text("지정된 숫자를 스크롤하여 찾으세요!")
                .foregroundStyle(.secondary)
            
            // 세로 스크롤 뷰에 숫자 목록 표시
            ScrollView(.vertical) {
                LazyVStack(spacing: 15) {
                    ForEach(numbers, id: \.self) { num in
                        Text("\(num)")
                            .font(.title3).bold()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(numberBackground(num: num))
                            .cornerRadius(8)
                            .onTapGesture {
                                handleNumberTap(num)
                            }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
            }
            .frame(maxHeight: 300)  // 스크롤 영역 높이 제한 (패널 안에 적당한 크기로)
            
            // 결과 표시
            if let time = gameState.lastScrollTime {
                Text(String(format: "✅ 완료: %.2f초 걸렸습니다", time))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(30)
        .onAppear {
            // ScrollViewGame 진입 시 로그
            if gameState.targetNumber == nil {
                print("경고: iPhone으로부터 목표 숫자를 아직 받지 못함.")
            }
        }
    }
    
    /// 숫자 항목의 배경색 결정 – 목표 숫자이면 강조 표시
    private func numberBackground(num: Int) -> Color {
        if let target = gameState.targetNumber, num == target {
            return Color.green.opacity(0.3)  // 목표 숫자를 연한 초록색 배경으로 강조
        } else {
            return Color.clear
        }
    }
    
    /// 숫자 탭 처리
    private func handleNumberTap(_ num: Int) {
        guard let target = gameState.targetNumber else { return }
        if num == target {
            // 올바른 숫자 선택
            gameState.completeScrollGame()
        } else {
            // 다른 숫자 선택 (여기서는 별도 처리 없음)
            print("오답 숫자 선택: \(num)")
        }
    }
}
