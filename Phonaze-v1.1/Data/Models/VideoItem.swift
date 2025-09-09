// Data/Models/VideoItem.swift
import Foundation

public struct VideoItem: Identifiable, Codable, Hashable {
    public let id: String                // unique (e.g., "tt-0001")
    public let title: String             // display title
    public let thumbName: String         // Assets.xcassets image name
    public let videoFileName: String     // e.g., "clip_01.mp4" (Media.bundle or main bundle)
    public let durationSec: Int?         // optional short clip length
    public let tags: [String]?           // optional
    public let overview: String?         // optional

    public init(
        id: String,
        title: String,
        thumbName: String,
        videoFileName: String,
        durationSec: Int? = nil,
        tags: [String]? = nil,
        overview: String? = nil
    ) {
        self.id = id
        self.title = title
        self.thumbName = thumbName
        self.videoFileName = videoFileName
        self.durationSec = durationSec
        self.tags = tags
        self.overview = overview
    }
}
