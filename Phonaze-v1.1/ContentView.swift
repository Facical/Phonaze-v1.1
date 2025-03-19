//
//  ContentView.swift
//  Phonaze
//
//  Created by 강형준 on 3/17/25.
//

// Views/ContentView.swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectivity: ConnectivityManager
    
    var body: some View {
        NavigationStack {  // 네비게이션 스택을 사용해 화면 전환 관리
            if connectivity.isConnected {
                // iPhone과 연결되었으면 홈 화면으로 이동
                HomeView()
            } else {
                // 연결 전이면 ConnectionView 표시
                ConnectionView()
            }
        }
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}
