import Foundation
import CoreGraphics

public enum InteractionMode: String, CaseIterable, Identifiable {
    case directTouch
    case pinch
    case phonaze   // iPhone 보조 컨트롤러

    public var id: String { rawValue }

    /// 드래그 → 스크롤 민감도
    public var scrollSensitivity: CGFloat {
        switch self {
        case .directTouch: return 1.0
        case .pinch:       return 1.2
        case .phonaze:     return 0.0 // 로컬 제스처 비활성
        }
    }

    /// 탭으로 판단할 드래그 총 이동량 기준 (pt)
    public var tapThreshold: CGFloat {
        switch self {
        case .directTouch: return 8
        case .pinch:       return 10
        case .phonaze:     return .greatestFiniteMagnitude
        }
    }

    /// 기본(플랫폼 무관) 인터셉트 여부
    public var interceptsLocalGestures: Bool {
        switch self {
        case .directTouch, .pinch: return true
        case .phonaze:             return false
        }
    }

    /// ✅ visionOS에선 WebView 네이티브 입력을 살리기 위해 항상 패스스루
    public var interceptsLocalGesturesForCurrentPlatform: Bool {
        #if os(visionOS)
        return false
        #else
        return interceptsLocalGestures
        #endif
    }
}

/// Interaction → Web 레이어로 전달하는 노티 이름
public enum InteractionNoti {
    public static let tap     = Notification.Name("EXP_TAP")
    public static let scrollH = Notification.Name("EXP_SCROLL_H")
    public static let scrollV = Notification.Name("EXP_SCROLL_V")
    public static let hoverTap = Notification.Name("EXP_HOVER_TAP")
}
