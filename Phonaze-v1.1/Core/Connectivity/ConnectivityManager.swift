// Core/Connectivity/ConnectivityManager.swift
import Foundation
import MultipeerConnectivity
import SwiftUI

/// Vision Pro (Host/Advertiser)
final class ConnectivityManager: NSObject, ObservableObject {
    private let serviceType = "phonaze-service"
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)

    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!

    // Published state
    @Published var isConnected: Bool = false
    @Published var connectedPeerName: String? = nil
    @Published var lastReceivedMessage: String = ""

    // External references (optional)
    weak var gameState: GameState?
    weak var experimentSession: ExperimentSession?
    weak var focusTracker: FocusTracker?

    // Notification keys for UI (scroll, tap)
    struct Noti {
        static let scrollH = Notification.Name("EXP_SCROLL_H")
        static let scrollV = Notification.Name("EXP_SCROLL_V")
        static let tap     = Notification.Name("EXP_TAP")
    }

    override init() {
        super.init()
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self

        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        advertiser.delegate = self
        advertiser.startAdvertisingPeer()
    }

    func setGameState(_ gameState: GameState) { self.gameState = gameState }
    func setExperimentSession(_ session: ExperimentSession) { self.experimentSession = session }
    func setFocusTracker(_ tracker: FocusTracker) { self.focusTracker = tracker }

    // MARK: Send
    func send(_ message: String) {
        guard !session.connectedPeers.isEmpty else { return }
        guard let data = message.data(using: .utf8) else { return }
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("Send failed: \(error.localizedDescription)")
        }
    }

    // Broadcast helpers (visionOS → iPhone, optional)
    func broadcastFocus(_ id: String) { send(EXPMessage.stateFocus(id)) }
    func broadcastTarget(_ id: String) { send(EXPMessage.stateTarget(id)) }
    func broadcastPhase(_ p: EXPPhase) { send(EXPMessage.statePhase(p)) }
    func broadcastScore(_ n: Int, _ goal: Int) { send(EXPMessage.stateScore(n, goal)) }
    func broadcastError(_ c: Int) { send(EXPMessage.stateError(c)) }

    // MARK: Lifecycle
    func disconnect() {
        print("Disconnecting session…")
        session.disconnect()
        DispatchQueue.main.async {
            self.isConnected = false
            self.connectedPeerName = nil
        }
        advertiser.stopAdvertisingPeer()
        advertiser.startAdvertisingPeer()
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
        print("Advertiser start failed: \(error.localizedDescription)")
    }
}

// MARK: - MCSessionDelegate
extension ConnectivityManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .connected:
                self.isConnected = true
                self.connectedPeerName = peerID.displayName
                print("Connected: \(peerID.displayName)")
            case .notConnected:
                self.isConnected = false
                print("Disconnected: \(peerID.displayName)")
            case .connecting:
                print("Connecting: \(peerID.displayName)")
            @unknown default:
                print("Unknown state: \(state.rawValue)")
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = String(data: data, encoding: .utf8) else { return }
        print("Received: \"\(message)\" from \(peerID.displayName)")

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lastReceivedMessage = message

            // === 1) Legacy handlers remain (WEB_*, SELECT/SCROLL/TAP) ===
            if message.hasPrefix("WEB_") {
                // BrowserView handles it via .onChange(lastReceivedMessage)
                return
            }

            if let gs = self.gameState {
                if message.hasPrefix("SELECT:") {
                    print("SELECT (legacy): \(message)")
                } else if message.hasPrefix("SCROLL_SELECT:") {
                    if let nStr = message.split(separator: ":").last,
                       let n = Int(nStr.trimmingCharacters(in: .whitespaces)) {
                        gs.startScrollGame(targetNumber: n)
                    }
                } else if message.hasPrefix("TAP") {
                    // handled inside SelectView via .onChange(lastReceivedMessage)
                }
            }

            // === 2) New EXP_* protocol ===
            switch EXPMessage.parseInbound(message) {
            case .tap:
                NotificationCenter.default.post(name: Noti.tap, object: nil)
                self.experimentSession?.confirmSelectionWithCurrentFocus()
            case .scrollH(let dx):
                NotificationCenter.default.post(name: Noti.scrollH, object: nil, userInfo: ["dx": dx])
            case .scrollV(let dy):
                NotificationCenter.default.post(name: Noti.scrollV, object: nil, userInfo: ["dy": dy])
            case .cmd(let cmd):
                self.handleCommand(cmd)
            case .unknown:
                break
            }
        }
    }

    private func handleCommand(_ cmd: EXPCommand) {
        switch cmd {
        case .start:
            experimentSession?.startOrContinue()
        case .next:
            experimentSession?.nextTrial()
        case .restart:
            experimentSession?.restart()
        case .cancel:
            experimentSession?.cancel()
        }
    }

    // Unused stream/resource methods
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
