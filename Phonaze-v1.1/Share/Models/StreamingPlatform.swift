import Foundation

public enum StreamingPlatform: String, CaseIterable, Identifiable {
    case netflix, youtube

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .netflix: return "Netflix"
        case .youtube: return "YouTube"
        }
    }

    public var subtitle: String {
        switch self {
        case .netflix: return "실제 넷플릭스 웹페이지로 이동"
        case .youtube: return "모바일 YouTube 페이지로 이동"
        }
    }

    public var assetName: String {
        switch self {
        case .netflix: return "Netflix_Logo" // Assets.xcassets 이름과 일치
        case .youtube: return "Youtube_Logo"
        }
    }

    public var urlString: String {
        switch self {
        case .netflix: return "https://www.netflix.com"
        case .youtube: return "https://m.youtube.com" // 초기 탐색 편의
        }
    }
}
