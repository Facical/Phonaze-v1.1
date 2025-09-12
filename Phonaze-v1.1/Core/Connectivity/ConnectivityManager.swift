// Phonaze-v1.1/Core/Connectivity/ConnectivityManager.swift

import Foundation
import MultipeerConnectivity
import SwiftUI

/// Vision Pro Host/Advertiser
@MainActor
final class ConnectivityManager: NSObject, ObservableObject {
    static let serviceType = "phonaze-service"

    // MARK: - MC
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private lazy var session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
    private lazy var advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: Self.serviceType)

    // MARK: - Published UI State
    @Published private(set) var isConnected = false
    @Published private(set) var connectedPeerName: String?
    @Published var lastReceivedMessage: String = ""
    @Published var lastReceivedWire: WireMessage?

    // MARK: - External references
    weak var gameState: GameState?
    weak var experimentSession: ExperimentSession?
    weak var focusTracker: FocusTracker?

    // MARK: - Notifications
    struct Noti {
        static let scrollH = Notification.Name("EXP_SCROLL_H")
        static let scrollV = Notification.Name("EXP_SCROLL_V")
        static let tap     = Notification.Name("EXP_TAP")
        static let hoverTap = Notification.Name("EXP_HOVER_TAP")
    }

    // MARK: - Lifecycle
    override init() {
        super.init()
        session.delegate = self
        advertiser.delegate = self
    }

    func start() {
        advertiser.startAdvertisingPeer()
        print("ConnectivityManager: advertising on \(Self.serviceType)")
    }

    func stop() {
        advertiser.stopAdvertisingPeer()
        session.disconnect()
        isConnected = false
        connectedPeerName = nil
        print("ConnectivityManager: stopped")
    }

    // External refs
    func setGameState(_ gameState: GameState) { self.gameState = gameState }
    func setExperimentSession(_ session: ExperimentSession) { self.experimentSession = session }
    func setFocusTracker(_ tracker: FocusTracker) { self.focusTracker = tracker }

    // MARK: - Send (JSON / RAW)
    func sendWire(_ message: WireMessage) {
        guard !session.connectedPeers.isEmpty else { return }
        do {
            let data = try MessageCodec.encode(message)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("sendWire error:", error.localizedDescription)
        }
    }

    func sendRaw(_ message: String) {
        guard !session.connectedPeers.isEmpty else { return }
        guard let data = message.data(using: .utf8) else { return }
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("sendRaw error:", error.localizedDescription)
        }
    }

    // Broadcast helpers
    func broadcastFocus(_ id: String) { sendRaw(EXPMessage.stateFocus(id)) }
    func broadcastTarget(_ id: String) { sendRaw(EXPMessage.stateTarget(id)) }
    func broadcastPhase(_ p: EXPPhase) { sendRaw(EXPMessage.statePhase(p)) }
    func broadcastScore(_ n: Int, _ goal: Int) { sendRaw(EXPMessage.stateScore(n, goal)) }
    func broadcastError(_ c: Int) { sendRaw(EXPMessage.stateError(c)) }

    // MARK: - Internal handling
    private func handle(_ data: Data, from peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            // 1) JSON 우선
            if let wm = try? MessageCodec.decode(data) {
                self.lastReceivedWire = wm
                self.route(wm)
                return
            }

            // 2) 문자열(레거시/WEB_*)
            guard let msg = String(data: data, encoding: .utf8) else { return }
            self.lastReceivedMessage = msg
            self.route(raw: msg)
        }
    }

    private func route(_ wm: WireMessage) {
        // ✅ 핵심 수정: WireMessage를 NotificationCenter로 전달
        switch wm {
        case .hello(let h):
            print("HELLO from \(h.role) v\(h.version)")

        case .ping(let p):
            self.sendWire(.pong(.init(t: p.t)))

        case .pong(let p):
            print("PONG latency ~\(Date().timeIntervalSince1970 - p.t) s")

        case .modeSet(let m):
            self.experimentSession?.log(kind: "mode_switch", payload: ["mode": m.mode])

        case .webTap(let t):
            print("📱 Routing webTap: (\(t.nx), \(t.ny))")
            NotificationCenter.default.post(
                name: ConnectivityManager.Noti.tap,
                object: nil,
                userInfo: ["nx": t.nx, "ny": t.ny]
            )
            self.experimentSession?.log(kind: "web_tap", payload: ["nx": "\(t.nx)", "ny": "\(t.ny)"])

        case .webScroll(let s):
            print("📱 Routing webScroll: dx=\(s.dx), dy=\(s.dy)")
            
            // ✅ 수평/수직 스크롤 모두 처리
            if s.dx != 0 {
                NotificationCenter.default.post(
                    name: ConnectivityManager.Noti.scrollH,
                    object: nil,
                    userInfo: ["dx": s.dx]
                )
            }
            if s.dy != 0 {
                NotificationCenter.default.post(
                    name: ConnectivityManager.Noti.scrollV,
                    object: nil,
                    userInfo: ["dy": s.dy]
                )
            }
            
            self.experimentSession?.log(kind: "web_scroll", payload: ["dx": "\(s.dx)", "dy": "\(s.dy)"])
                
        case .webHoverTap:
            print("ConnectivityManager: Received webHoverTap - triggering native tap")
            NotificationCenter.default.post(
                name: ConnectivityManager.Noti.hoverTap,
                object: nil
            )
            self.experimentSession?.log(kind: "web_hover_tap", payload: [:])
        }
    }

    private func route(raw message: String) {
        // 0) WEB_*는 Browser(Web 레이어)에서 onChange로 직접 처리하므로 전달만
        if message.hasPrefix("WEB_") {
            return
        }

        // 1) EXP_* (레거시) 처리
        switch EXPMessage.parseInbound(message) {
        case .tap:
            NotificationCenter.default.post(name: Noti.tap, object: nil)
            experimentSession?.confirmSelectionWithCurrentFocus()
            experimentSession?.log(kind: "web_tap", payload: [:])

        case .scrollH(let dx):
            NotificationCenter.default.post(name: Noti.scrollH, object: nil, userInfo: ["dx": dx])
            experimentSession?.log(kind: "web_scroll", payload: ["dx": "\(dx)", "dy": "0"])

        case .scrollV(let dy):
            NotificationCenter.default.post(name: Noti.scrollV, object: nil, userInfo: ["dy": dy])
            experimentSession?.log(kind: "web_scroll", payload: ["dx": "0", "dy": "\(dy)"])

        case .cmd(let cmd):
            handleCommand(cmd)

        case .unknown:
            break
        }
    }

    private func handleCommand(_ cmd: EXPCommand) {
        switch cmd {
        case .start:   experimentSession?.startOrContinue()
        case .next:    experimentSession?.nextTrial()
        case .restart: experimentSession?.restart()
        case .cancel:  experimentSession?.cancel()
        }
    }
}

// MARK: - Advertiser
extension ConnectivityManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("Invitation from \(peerID.displayName) → auto-accept")
        invitationHandler(true, session)
    }
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Advertiser start failed:", error.localizedDescription)
    }
}

// MARK: - MCSessionDelegate
extension ConnectivityManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            switch state {
            case .connected:
                self?.isConnected = true
                self?.connectedPeerName = peerID.displayName
                print("Connected:", peerID.displayName)
                // handshake
                self?.sendWire(.hello(.init(role: .vision, version: 1, capabilities: Hello.defaultCaps)))
                self?.sendWire(.ping(.init(t: Date().timeIntervalSince1970)))
            case .notConnected:
                self?.isConnected = false
                self?.connectedPeerName = nil
                print("Disconnected:", peerID.displayName)
            case .connecting:
                print("Connecting:", peerID.displayName)
            @unknown default:
                print("Unknown MC state:", state.rawValue)
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        handle(data, from: peerID)
    }

    // Unused stream/resource
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension ConnectivityManager {
    func sendMode(_ mode: InteractionMode) {
        sendWire(.modeSet(.init(mode: mode.rawValue)))
    }
}
