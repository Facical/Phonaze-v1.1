// Core/Connectivity/MessageProtocol.swift
import Foundation

/// String-based lightweight protocol for cross-device messages.
/// iPhone → visionOS:
///   - EXP_TAP
///   - EXP_SCROLL_H:<dx>
///   - EXP_SCROLL_V:<dy>
///   - EXP_CMD:<START|NEXT|RESTART|CANCEL>
/// visionOS → iPhone (optional status broadcast):
///   - EXP_STATE:FOCUS:<itemId>
///   - EXP_STATE:TARGET:<itemId>
///   - EXP_STATE:PHASE:<phase>
///   - EXP_STATE:SCORE:<n>/<goal>
///   - EXP_STATE:ERROR:<count>
enum EXPPrefix {
    static let tap        = "EXP_TAP"
    static let scrollH    = "EXP_SCROLL_H:"
    static let scrollV    = "EXP_SCROLL_V:"
    static let cmd        = "EXP_CMD:"
    static let stateFocus = "EXP_STATE:FOCUS:"
    static let stateTarget = "EXP_STATE:TARGET:"
    static let statePhase  = "EXP_STATE:PHASE:"
    static let stateScore  = "EXP_STATE:SCORE:"
    static let stateError  = "EXP_STATE:ERROR:"
}

enum EXPCommand: String {
    case start   = "START"
    case next    = "NEXT"
    case restart = "RESTART"
    case cancel  = "CANCEL"
}

enum EXPPhase: String {
    case idle, ready, browse, select, play, end
}

enum EXPInbound {
    case tap
    case scrollH(Double)
    case scrollV(Double)
    case cmd(EXPCommand)
    case unknown(String)
}

struct EXPMessage {
    // MARK: Build status messages (visionOS → iPhone)
    static func stateFocus(_ id: String) -> String { "\(EXPPrefix.stateFocus)\(id)" }
    static func stateTarget(_ id: String) -> String { "\(EXPPrefix.stateTarget)\(id)" }
    static func statePhase(_ p: EXPPhase) -> String { "\(EXPPrefix.statePhase)\(p.rawValue)" }
    static func stateScore(_ n: Int, _ goal: Int) -> String { "\(EXPPrefix.stateScore)\(n)/\(goal)" }
    static func stateError(_ count: Int) -> String { "\(EXPPrefix.stateError)\(count)" }

    // MARK: Parse iPhone → visionOS
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
