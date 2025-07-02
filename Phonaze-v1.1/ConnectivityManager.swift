//
//  ConnectivityManager.swift
//  Phonaze_VisionPro
//
//  Created by YourName on 3/18/25.
//

import Foundation
import MultipeerConnectivity

/// Vision Pro(Host) 측에서만 Advertiser를 실행하여, iPhone(클라이언트)로부터 초대를 받지 않고,
/// 대신 iPhone이 발견 후 연결 초대를 보내면 이쪽(Host)에서 받아들이는 구조입니다.
class ConnectivityManager: NSObject, ObservableObject {
    private let serviceType = "phonaze-service"
    
    // 본인 피어 ID
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    
    private var session: MCSession!
    private var advertiser: MCNearbyServiceAdvertiser!  // Host는 Advertiser만 사용 (Browser 제거)
    
    // 연결 상태 표시용
    @Published var isConnected: Bool = false
    @Published var connectedPeerName: String? = nil
    @Published var lastReceivedMessage: String = ""
    
    // 게임 상태 (선택사항)
    var gameState: GameState?
    
    override init() {
        super.init()
        
        // MCSession 생성
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
        // Advertiser 초기화
        advertiser = MCNearbyServiceAdvertiser(peer: myPeerID,
                                               discoveryInfo: nil,
                                               serviceType: serviceType)
        advertiser.delegate = self
        
        // Vision Pro에서 광고 시작 (iPhone이 이걸 발견하고 연결 초대)
        advertiser.startAdvertisingPeer()
    }
    
    /// GameState 객체 연결 (게임 로직 등에서 필요 시)
    func setGameState(_ gameState: GameState) {
        self.gameState = gameState
    }
    
    /// 연결된 iPhone에 메시지 전송
    func send(message: String) {
        guard !session.connectedPeers.isEmpty else { return }
        if let data = message.data(using: .utf8) {
            do {
                try session.send(data, toPeers: session.connectedPeers, with: .reliable)
            } catch {
                print("데이터 전송 실패: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate
extension ConnectivityManager: MCNearbyServiceAdvertiserDelegate {
    /// iPhone(클라이언트)에서 초대가 오면 자동 수락
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser,
                    didReceiveInvitationFromPeer peerID: MCPeerID,
                    withContext context: Data?,
                    invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        print("초대 수신: \(peerID.displayName) - 자동 수락 진행")
        // 자동으로 수락
        invitationHandler(true, session)
    }
    
    /// Advertiser 시작 실패 시
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("광고 시작 실패: \(error.localizedDescription)")
    }
}

// MARK: - MCSessionDelegate (연결 상태 & 데이터 수신)
extension ConnectivityManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .connected:
                self.isConnected = true
                self.connectedPeerName = peerID.displayName
                print("피어 연결됨: \(peerID.displayName)")
            case .notConnected:
                self.isConnected = false
                print("피어 연결 끊어짐: \(peerID.displayName)")
            case .connecting:
                print("피어 연결 중: \(peerID.displayName)")
            @unknown default:
                print("알 수 없는 세션 상태: \(state.rawValue)")
            }
        }
    }
    
    // iPhone에서 보낸 데이터 수신
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        guard let message = String(data: data, encoding: .utf8) else { return }
        print("수신 데이터: \"\(message)\" from \(peerID.displayName)")
        
        // 마지막 수신 메시지 업데이트
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.lastReceivedMessage = message
            
            // 게임 로직에 전달 (기존 코드)
            if let gameState = self.gameState {
                // 단순 예시: "SELECT:x,y" 좌표이면 SelectGame, "SCROLL_SELECT:숫자"이면 ScrollGame
                if message.hasPrefix("SELECT:") {
                    // SelectView에서 메시지 처리할 수 있도록 함
                    print("SELECT 메시지 수신: \(message)")
                } else if message.hasPrefix("SCROLL_SELECT:") {
                    if let numberStr = message.split(separator: ":").last,
                       let number = Int(numberStr.trimmingCharacters(in: .whitespaces)) {
                        gameState.startScrollGame(targetNumber: number)
                    }
                } else {
                    print("알 수 없는 형식의 메시지 수신: \(message)")
                }
            }
        }
    }
    
    // 스트림 등 다른 메서드는 사용 안 함
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String,
                 fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
