import Foundation
import Combine

/// 원격(iPhone) 스크롤 신호에 보정 계수를 적용하고 싶을 때 사용.
/// 기본적으로는 사용하지 않아도 됨.
final class RemoteTouchAdapter: ObservableObject {
    var scaleX: Double = 1.0
    var scaleY: Double = 1.0

    private var bag = Set<AnyCancellable>()

    func attach() {
        NotificationCenter.default.publisher(for: InteractionNoti.scrollH)
            .sink { note in
                guard let dx = note.userInfo?["dx"] as? Double else { return }
                NotificationCenter.default.post(name: InteractionNoti.scrollH, object: nil, userInfo: ["dx": dx * self.scaleX])
            }.store(in: &bag)

        NotificationCenter.default.publisher(for: InteractionNoti.scrollV)
            .sink { note in
                guard let dy = note.userInfo?["dy"] as? Double else { return }
                NotificationCenter.default.post(name: InteractionNoti.scrollV, object: nil, userInfo: ["dy": dy * self.scaleY])
            }.store(in: &bag)
    }

    func detach() { bag.removeAll() }
}
