import SwiftUI

struct ConnectionView: View {
    @EnvironmentObject var connectivity: ConnectivityManager

    /// 닫기/복귀 콜백 (예: ContentView에서 route를 .start로 되돌림)
    var onDone: (() -> Void)? = nil

    @State private var autoDismissWork: DispatchWorkItem?

    var body: some View {
        VStack(spacing: 24) {
            header

            if connectivity.isConnected {
                Image(systemName: "iphone.gen3.radiowaves.left.and.right.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.green)
                Text("iPhone 연결 성공").font(.title).bold()
                Text(connectivity.connectedPeerName ?? "연결됨")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button("연결 해제") { connectivity.stop() }
                        .buttonStyle(.bordered)
                    Button("완료") { onDone?() }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.6)
                Text("iPhone을 연결해주세요").font(.title2).bold()
                Text("iPhone 앱에서 ‘Vision Pro에 연결’을 눌러주세요.")
                    .font(.callout).foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button("연결 대기 시작") { connectivity.start() }
                        .buttonStyle(.borderedProminent)
                    Button("중지") { connectivity.stop() }
                        .buttonStyle(.bordered)
                }
            }

            Spacer()
        }
        .padding(24)
        .navigationTitle("Connection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let onDone {
                    Button("닫기") { onDone() }
                }
            }
        }
        // 앱이 들어오면 광고 시작 (이미 시작돼 있어도 안전)
        .task { connectivity.start() }
        // 연결되면 약간의 지연 뒤 자동 닫기(선택)
        .onChange(of: connectivity.isConnected) { _, connected in
            autoDismissWork?.cancel()
            guard connected, let onDone else { return }
            let work = DispatchWorkItem { onDone() }
            autoDismissWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(connectivity.isConnected ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            Text(connectivity.isConnected
                 ? "Connected\(connectivity.connectedPeerName.map { " · \($0)" } ?? "")"
                 : "Not Connected")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
