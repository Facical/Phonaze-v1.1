import SwiftUI
import Combine

/// WebView 위에 올려 제스처를 수집하는 투명 오버레이.
/// ✅ visionOS에선 hit-testing을 꺼서 WebView가 직접 입력을 받게 한다.
public struct InteractionOverlay: View {
    public let mode: InteractionMode

    @State private var startLocation: CGPoint?
    @State private var lastLocation: CGPoint?
    @State private var totalDistance: CGFloat = 0

    public init(mode: InteractionMode) { self.mode = mode }

    public var body: some View {
        GeometryReader { geo in
            // visionOS: 패스스루 / 그 외: 기존 동작
            let intercept = mode.interceptsLocalGesturesForCurrentPlatform

            Color.clear
                .contentShape(Rectangle())
                .modifier(GestureModifier(enabled: intercept, geo: geo, mode: mode,
                                          startLocation: $startLocation,
                                          lastLocation: $lastLocation,
                                          totalDistance: $totalDistance))
                .allowsHitTesting(intercept)  // ✅ visionOS=false → 패스스루
        }
    }
}

// MARK: - 내부 제스처 모디파이어
private struct GestureModifier: ViewModifier {
    let enabled: Bool
    let geo: GeometryProxy
    let mode: InteractionMode
    @Binding var startLocation: CGPoint?
    @Binding var lastLocation: CGPoint?
    @Binding var totalDistance: CGFloat

    func body(content: Content) -> some View {
        if enabled {
            content
                .gesture(dragGesture)
                .highPriorityGesture(tapGesture)
        } else {
            content // 제스처/히트테스트 비활성 → WebView가 직접 입력 수신
        }
    }

    private var tapGesture: some Gesture {
        TapGesture(count: 1).onEnded {
            let pt = lastLocation ?? CGPoint(x: geo.size.width/2, y: geo.size.height/2)
            postTap(point: pt)
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                if startLocation == nil {
                    startLocation = value.startLocation
                    totalDistance = 0
                }
                let prev = lastLocation ?? value.startLocation
                let curr = value.location
                lastLocation = curr

                totalDistance += hypot(curr.x - prev.x, curr.y - prev.y)

                let dx = Double((curr.x - prev.x) * mode.scrollSensitivity)
                let dy = Double((curr.y - prev.y) * mode.scrollSensitivity)
                postScroll(dx: dx, dy: dy)
            }
            .onEnded { value in
                let endPt = value.location
                if totalDistance <= mode.tapThreshold {
                    postTap(point: endPt)
                }
                startLocation = nil
                lastLocation  = nil
                totalDistance = 0
            }
    }

    // MARK: - 노티 발행 (JS 주입 경로는 PlatformWebView가 처리)
    private func postScroll(dx: Double, dy: Double) {
        if dx != 0 { NotificationCenter.default.post(name: InteractionNoti.scrollH, object: nil, userInfo: ["dx": dx]) }
        if dy != 0 { NotificationCenter.default.post(name: InteractionNoti.scrollV, object: nil, userInfo: ["dy": dy]) }
    }

    private func postTap(point: CGPoint) {
        let w = max(1, geo.size.width)
        let h = max(1, geo.size.height)
        let nx = Double(min(max(0, point.x / w), 1))
        let ny = Double(min(max(0, point.y / h), 1))
        NotificationCenter.default.post(name: InteractionNoti.tap, object: nil, userInfo: ["nx": nx, "ny": ny])
    }
}
