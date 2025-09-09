import Foundation

struct ExperimentConfig: Codable {
    var participantID: String
    var goalTrials: Int

    /// 브라우징 태스크 명시(확장 대비)
    var taskType: String = "mediaBrowsing"          // "mediaBrowsing"
    /// 선택 플랫폼
    var platform: String? = nil                     // "netflix" | "youtube"
    /// 인터랙션 모드
    var interactionMode: String = "directTouch"     // "directTouch" | "pinch" | "phonaze"

    /// 미리 정의된 타깃 시퀀스(없으면 UI에서 설정/생성)
    var targetSequence: [String] = []

    static func `default`(participantID: String) -> ExperimentConfig {
        ExperimentConfig(
            participantID: participantID,
            goalTrials: 10,
            taskType: "mediaBrowsing",
            platform: nil,
            interactionMode: "directTouch",
            targetSequence: []
        )
    }
}
