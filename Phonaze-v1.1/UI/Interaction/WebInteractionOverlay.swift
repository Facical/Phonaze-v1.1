import SwiftUI
import Combine

/// WebView 위에 올려 제스처를 수집하는 투명 오버레이.
/// - directTouch/pinch: 로컬 제스처를 인터셉트 → EXP_* 알림 발행
/// - phonaze: 제스처 패스스루(오버레이는 비활성)
public struct InteractionOverlay: View {
    public let mode: InteractionMode

    @State private var startLocation: CGPoint?
    @State private var lastLocation: CGPoint?
    @State private var totalDistance: CGFloat = 0

    public init(mode: InteractionMode) {
        self.mode = mode
    }

    public var body: some View {
        GeometryReader { geo in
            Color.clear
                .contentShape(Rectangle())
                .gesture(dragGesture(in: geo))
                .highPriorityGesture(tapGesture(in: geo))
                .allowsHitTesting(mode.interceptsLocalGestures)   // phonaze면 패스스루
        }
    }

    // MARK: - Gestures

    private func tapGesture(in geo: GeometryProxy) -> some Gesture {
        TapGesture(count: 1).onEnded {
            guard mode.interceptsLocalGestures else { return }
            // 마지막 위치가 있으면 그 좌표로 탭, 없으면 중앙
            let pt = lastLocation ?? CGPoint(x: geo.size.width/2, y: geo.size.height/2)
            postTap(point: pt, in: geo)
        }
    }

    private func dragGesture(in geo: GeometryProxy) -> some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard mode.interceptsLocalGestures else { return }
                if startLocation == nil {
                    startLocation = value.startLocation
                    totalDistance = 0
                }
                let prev = lastLocation ?? value.startLocation
                let curr = value.location
                lastLocation = curr

                // 이동거리 누적(탭/드래그 판별용)
                totalDistance += hypot(curr.x - prev.x, curr.y - prev.y)

                // 스크롤 송출 (변위 차이)
                let dx = Double((curr.x - prev.x) * mode.scrollSensitivity)
                let dy = Double((curr.y - prev.y) * mode.scrollSensitivity)
                postScroll(dx: dx, dy: dy)
            }
            .onEnded { value in
                guard mode.interceptsLocalGestures else { return }
                let endPt = value.location
                // "거의 움직이지 않았다"면 탭으로 처리
                if totalDistance <= mode.tapThreshold {
                    postTap(point: endPt, in: geo)
                }
                // 상태 리셋
                startLocation = nil
                lastLocation = nil
                totalDistance = 0
            }
    }

    // MARK: - Post helpers

    private func postScroll(dx: Double, dy: Double) {
        if dx != 0 {
            NotificationCenter.default.post(name: InteractionNoti.scrollH, object: nil, userInfo: ["dx": dx])
        }
        if dy != 0 {
            NotificationCenter.default.post(name: InteractionNoti.scrollV, object: nil, userInfo: ["dy": dy])
        }
    }

    private func postTap(point: CGPoint, in geo: GeometryProxy) {
        let w = max(1, geo.size.width)
        let h = max(1, geo.size.height)
        // 정규화 좌표(0~1)
        let nx = Double(min(max(0, point.x / w), 1))
        let ny = Double(min(max(0, point.y / h), 1))
        NotificationCenter.default.post(name: InteractionNoti.tap, object: nil, userInfo: ["nx": nx, "ny": ny])
    }
}
