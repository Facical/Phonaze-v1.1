// Data/Repository/LocalMediaRepository.swift
import Foundation
import Combine

/// Loads media catalog from bundled JSON and resolves local video URLs.
public final class LocalMediaRepository: ObservableObject {
    @Published public private(set) var catalog: MediaCatalog = MediaCatalog(sections: [])
    @Published public private(set) var isLoaded: Bool = false

    public init() {}

    // MARK: Load

    @discardableResult
    public func load() -> Bool {
        if let url = Bundle.main.url(forResource: "media_catalog", withExtension: "json") {
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode(MediaCatalog.self, from: data)
                DispatchQueue.main.async {
                    self.catalog = decoded
                    self.isLoaded = true
                }
                return true
            } catch {
                print("LocalMediaRepository: JSON decode failed → \(error.localizedDescription)")
            }
        } else {
            print("LocalMediaRepository: media_catalog.json not found in main bundle.")
        }

        // Fallback to sample
        let sample = LocalMediaRepository.sampleCatalog()
        DispatchQueue.main.async {
            self.catalog = sample
            self.isLoaded = true
        }
        return false
    }

    // MARK: Query

    public func allSections() -> [SectionModel] { catalog.sections }

    public func section(by id: String) -> SectionModel? {
        catalog.sections.first(where: { $0.id == id })
    }

    public func item(by id: String) -> VideoItem? {
        for s in catalog.sections {
            if let hit = s.items.first(where: { $0.id == id }) { return hit }
        }
        return nil
    }

    /// Resolve a playable local URL for an item.
    /// Looks up in main bundle first, then in "Media.bundle".
    public func videoURL(for item: VideoItem) -> URL? {
        // direct (flattened) resource
        if let u = Bundle.main.url(forResource: item.videoFileName, withExtension: nil) {
            return u
        }
        // inside Media.bundle subdirectory
        if let u = Bundle.main.url(forResource: item.videoFileName,
                                   withExtension: nil,
                                   subdirectory: "Media.bundle") {
            return u
        }
        // inside nested bundle named "Media"
        if let mediaBundleURL = Bundle.main.url(forResource: "Media", withExtension: "bundle"),
           let mediaBundle = Bundle(url: mediaBundleURL),
           let u = mediaBundle.url(forResource: (item.videoFileName as NSString).deletingPathExtension,
                                   withExtension: (item.videoFileName as NSString).pathExtension) {
            return u
        }
        print("LocalMediaRepository: video not found → \(item.videoFileName)")
        return nil
    }

    // MARK: Preview / Fallback

    public static func sampleCatalog() -> MediaCatalog {
        let s1 = SectionModel(
            id: "sec-critically",
            title: "Critically Acclaimed",
            items: [
                VideoItem(id: "tt-0001", title: "Blazing Chef",
                          thumbName: "thumb_blazing_chef", videoFileName: "clip_cooking.mp4",
                          durationSec: 8, tags: ["food", "drama"], overview: "High-heat culinary showdown."),
                VideoItem(id: "tt-0002", title: "Stone Valley",
                          thumbName: "thumb_stone_valley", videoFileName: "clip_nature.mp4",
                          durationSec: 7, tags: ["nature"], overview: "A quiet walk through misty hills.")
            ])

        let s2 = SectionModel(
            id: "sec-crowd",
            title: "Crowd Pleasers",
            items: [
                VideoItem(id: "tt-0010", title: "Metro Chase",
                          thumbName: "thumb_metro_chase", videoFileName: "clip_action.mp4",
                          durationSec: 9, tags: ["action"], overview: "A tense sprint across the city."),
                VideoItem(id: "tt-0011", title: "Retro Beats",
                          thumbName: "thumb_retro_beats", videoFileName: "clip_music.mp4",
                          durationSec: 6, tags: ["music"], overview: "Neon grooves and synth vibes.")
            ])

        let s3 = SectionModel(
            id: "sec-jp",
            title: "Japanese TV Shows",
            items: [
                VideoItem(id: "tt-0020", title: "Volley High",
                          thumbName: "thumb_volley_high", videoFileName: "clip_sport.mp4",
                          durationSec: 8, tags: ["sports"], overview: "Quick rallies and big comebacks."),
                VideoItem(id: "tt-0021", title: "Mystic Library",
                          thumbName: "thumb_mystic_library", videoFileName: "clip_fantasy.mp4",
                          durationSec: 7, tags: ["fantasy"], overview: "A door opens to timeless knowledge.")
            ])

        return MediaCatalog(sections: [s1, s2, s3])
    }
}
