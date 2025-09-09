// Data/Models/SectionModel.swift
import Foundation

public struct SectionModel: Identifiable, Codable, Hashable {
    public let id: String        // e.g., "sec-trending"
    public let title: String     // e.g., "Trending Now"
    public var items: [VideoItem]

    public init(id: String, title: String, items: [VideoItem]) {
        self.id = id
        self.title = title
        self.items = items
    }
}

/// Top-level catalog container for JSON seeds.
public struct MediaCatalog: Codable {
    public var sections: [SectionModel]
}
