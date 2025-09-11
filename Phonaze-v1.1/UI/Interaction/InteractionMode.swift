import Foundation
import CoreGraphics

public enum InteractionMode: String, CaseIterable, Identifiable {
    case directTouch
    case pinch
    case phonaze   // iPhone 보조 컨트롤러

    public var id: String { rawValue }

    /// 드래그 → 스크롤 민감도 (레거시 호환용)
    public var scrollSensitivity: CGFloat {
        switch self {
        case .directTouch: return 1.0
        case .pinch:       return 1.2
        case .phonaze:     return 0.0 // 로컬 제스처 비활성
        }
    }

    /// 탭으로 판단할 드래그 총 이동량 기준 (pt) - 레거시 호환용
    public var tapThreshold: CGFloat {
        switch self {
        case .directTouch: return 8
        case .pinch:       return 10
        case .phonaze:     return .greatestFiniteMagnitude
        }
    }

    /// ✅ visionOS에서는 WebView 네이티브 입력을 살리기 위해 항상 패스스루
    /// 다른 플랫폼에서는 기존 동작 유지
    public var shouldInterceptGestures: Bool {
        #if os(visionOS)
        // Vision Pro에서는 네이티브 시선 추적 + 탭을 활용하므로 인터셉트 안함
        return false
        #else
        // iPhone/iPad에서는 기존 동작 유지
        switch self {
        case .directTouch, .pinch: return true
        case .phonaze:             return false
        }
        #endif
    }
    
    /// UI 표시용 설명
    public var displayName: String {
        switch self {
        case .directTouch: return "Direct Touch"
        case .pinch:       return "Pinch Gesture"
        case .phonaze:     return "Phonaze (iPhone)"
        }
    }
    
    /// 상세 설명
    public var description: String {
        switch self {
        case .directTouch:
            #if os(visionOS)
            return "Native Vision Pro eye tracking + tap"
            #else
            return "Direct touch interaction"
            #endif
        case .pinch:
            return "Pinch and drag gestures"
        case .phonaze:
            return "iPhone as remote controller"
        }
    }
}

/// Interaction → Web 레이어로 전달하는 노티 이름
public enum InteractionNoti {
    public static let tap     = Notification.Name("EXP_TAP")
    public static let scrollH = Notification.Name("EXP_SCROLL_H")
    public static let scrollV = Notification.Name("EXP_SCROLL_V")
    public static let hoverTap = Notification.Name("EXP_HOVER_TAP") // ✅ iPhone → Vision Pro 시선 기반 탭
}
