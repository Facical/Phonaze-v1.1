//
//  ConnectionView.swift
//  Phonaze
//
//  Created by 강형준 on 3/18/25.
//

// Views/ConnectionView.swift
import SwiftUI

struct ConnectionView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    
    var body: some View {
        VStack(spacing: 20) {
            Text("📡 Phonaze 연결").font(.title2).bold()
            if connectivity.isConnected {
                // 연결되었을 경우 (이 화면이 표시될 일은 거의 없음 - ContentView가 전환함)
                Text("연결 성공: \(connectivity.connectedPeerName ?? "iPhone")")
                    .foregroundStyle(.green)
            } else {
                // 연결 시도 중인 경우
                Text("iPhone을 찾는 중...").foregroundStyle(.secondary)
                ProgressView().progressViewStyle(CircularProgressViewStyle())
                    .padding()
            }
        }
        .padding(40)
        .background(.ultraThinMaterial)  // 시각적 효과 배경 (VisionOS에서는 창 스타일로 활용)
        .cornerRadius(20)
    }
}
