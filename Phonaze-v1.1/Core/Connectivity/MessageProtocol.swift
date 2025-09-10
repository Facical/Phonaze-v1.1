import Foundation

// MARK: - JSON 기반 메시지
enum WireMessage: Codable, Equatable {
    case hello(Hello)
    case ping(Ping)
    case pong(Pong)
    case modeSet(ModeSet)          // "directTouch" | "pinch" | "phonaze"
    case webTap(WebTap)            // 탭 좌표: [0,1] 정규화
    case webScroll(WebScroll)      // 스크롤: dx, dy (pt 단위, 상대)

    enum CodingKeys: String, CodingKey { case type, payload }
    enum Kind: String, Codable { case hello, ping, pong, modeSet, webTap, webScroll }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(Kind.self, forKey: .type) {
        case .hello:    self = .hello(try c.decode(Hello.self,    forKey: .payload))
        case .ping:     self = .ping( try c.decode(Ping.self,     forKey: .payload))
        case .pong:     self = .pong( try c.decode(Pong.self,     forKey: .payload))
        case .modeSet:  self = .modeSet(try c.decode(ModeSet.self,forKey: .payload))
        case .webTap:   self = .webTap(try c.decode(WebTap.self,  forKey: .payload))
        case .webScroll:self = .webScroll(try c.decode(WebScroll.self,forKey: .payload))
        }
    }
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .hello(let p):    try c.encode(Kind.hello,   forKey: .type); try c.encode(p, forKey: .payload)
        case .ping(let p):     try c.encode(Kind.ping,    forKey: .type); try c.encode(p, forKey: .payload)
        case .pong(let p):     try c.encode(Kind.pong,    forKey: .type); try c.encode(p, forKey: .payload)
        case .modeSet(let p):  try c.encode(Kind.modeSet, forKey: .type); try c.encode(p, forKey: .payload)
        case .webTap(let p):   try c.encode(Kind.webTap,  forKey: .type); try c.encode(p, forKey: .payload)
        case .webScroll(let p):try c.encode(Kind.webScroll,forKey: .type);try c.encode(p, forKey: .payload)
        }
    }
}

struct Hello: Codable, Equatable {
    enum Role: String, Codable, Equatable { case vision, iphone }
    struct Caps: Codable, Equatable { var jsTap: Bool; var nativeScroll: Bool }
    let role: Role
    let version: Int
    let capabilities: Caps
    static let `defaultCaps` = Caps(jsTap: true, nativeScroll: true)
}
struct Ping: Codable, Equatable { let t: TimeInterval }
struct Pong: Codable, Equatable { let t: TimeInterval }
struct ModeSet: Codable, Equatable { let mode: String } // "directTouch" | "pinch" | "phonaze"
struct WebTap: Codable, Equatable { let nx: Double, ny: Double } // [0,1]
struct WebScroll: Codable, Equatable { let dx: Double, dy: Double } // pt 상대이동

enum MessageCodec {
    static let encoder = JSONEncoder()
    static let decoder = JSONDecoder()
    static func encode(_ m: WireMessage) throws -> Data { try encoder.encode(m) }
    static func decode(_ d: Data) throws -> WireMessage { try decoder.decode(WireMessage.self, from: d) }
}

// MARK: - 문자열 기반(레거시) EXP_* / WEB_* 프로토콜
enum EXPPrefix {
    static let tap         = "EXP_TAP"
    static let scrollH     = "EXP_SCROLL_H:"
    static let scrollV     = "EXP_SCROLL_V:"
    static let cmd         = "EXP_CMD:"
    static let stateFocus  = "EXP_STATE:FOCUS:"
    static let stateTarget = "EXP_STATE:TARGET:"
    static let statePhase  = "EXP_STATE:PHASE:"
    static let stateScore  = "EXP_STATE:SCORE:"
    static let stateError  = "EXP_STATE:ERROR:"
}

enum EXPCommand: String { case start = "START", next = "NEXT", restart = "RESTART", cancel = "CANCEL" }
enum EXPPhase: String { case idle, ready, browse, select, play, end }

enum EXPInbound {
    case tap
    case scrollH(Double)
    case scrollV(Double)
    case cmd(EXPCommand)
    case unknown(String)
}

struct EXPMessage {
    // visionOS → iPhone
    static func stateFocus(_ id: String) -> String { "\(EXPPrefix.stateFocus)\(id)" }
    static func stateTarget(_ id: String) -> String { "\(EXPPrefix.stateTarget)\(id)" }
    static func statePhase(_ p: EXPPhase) -> String { "\(EXPPrefix.statePhase)\(p.rawValue)" }
    static func stateScore(_ n: Int, _ goal: Int) -> String { "\(EXPPrefix.stateScore)\(n)/\(goal)" }
    static func stateError(_ count: Int) -> String { "\(EXPPrefix.stateError)\(count)" }

    // iPhone → visionOS
    static func parseInbound(_ raw: String) -> EXPInbound {
        if raw == EXPPrefix.tap { return .tap }
        if raw.hasPrefix(EXPPrefix.scrollH),
           let v = Double(raw.dropFirst(EXPPrefix.scrollH.count)) { return .scrollH(v) }
        if raw.hasPrefix(EXPPrefix.scrollV),
           let v = Double(raw.dropFirst(EXPPrefix.scrollV.count)) { return .scrollV(v) }
        if raw.hasPrefix(EXPPrefix.cmd) {
            let body = String(raw.dropFirst(EXPPrefix.cmd.count))
            if let c = EXPCommand(rawValue: body) { return .cmd(c) }
            return .unknown(raw)
        }
        return .unknown(raw)
    }
}
