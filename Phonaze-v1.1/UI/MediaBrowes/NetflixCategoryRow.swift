// Phonaze-v1.1/UI/MediaBrowse/NetflixCategoryRow.swift
import SwiftUI

struct NetflixCategoryRow: View {
    let sectionID: String
    let sectionTitle: String
    @ObservedObject var focusTracker: FocusTracker
    @Binding var activeSectionID: String?
    var onSelectItem: (VideoItem) -> Void
    
    @State private var scrollOffset: CGFloat = 0
    @State private var currentIndex: Int = 0
    
    // Sample Netflix-like content
    private var items: [VideoItem] {
        generateNetflixContent(for: sectionTitle)
    }
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(items) { item in
                        NetflixThumbnail(
                            item: item,
                            isFocused: focusTracker.currentFocusedID == item.id,
                            isTopTen: sectionTitle.contains("Top 10"),
                            rank: items.firstIndex(where: { $0.id == item.id }) ?? 0
                        )
                        .id(item.id)
                        .onHover { isHovering in
                            if isHovering {
                                focusTracker.updateCandidate(id: item.id)
                                activeSectionID = sectionID
                            }
                        }
                        .onTapGesture {
                            onSelectItem(item)
                        }
                    }
                }
                .padding(.horizontal, 50)
            }
            .frame(height: sectionTitle.contains("Top 10") ? 200 : 160)
            .onChange(of: activeSectionID) { newValue in
                if newValue == sectionID {
                    // This section is now active for scrolling
                }
            }
        }
    }
    
    private func generateNetflixContent(for section: String) -> [VideoItem] {
        switch section {
        case "Critically Acclaimed TV Shows":
            return [
                VideoItem(id: "cr-001", title: "Wednesday", thumbName: "thumb_wednesday",
                         videoFileName: "clip_wednesday.mp4", tags: ["New Episodes"]),
                VideoItem(id: "cr-002", title: "SOLO", thumbName: "thumb_solo",
                         videoFileName: "clip_solo.mp4", tags: ["New Episode", "Watch Now"]),
                VideoItem(id: "cr-003", title: "Squid Game", thumbName: "thumb_squid",
                         videoFileName: "clip_squid.mp4"),
                VideoItem(id: "cr-004", title: "The Glory", thumbName: "thumb_glory",
                         videoFileName: "clip_glory.mp4"),
                VideoItem(id: "cr-005", title: "Suits", thumbName: "thumb_suits",
                         videoFileName: "clip_suits.mp4"),
                VideoItem(id: "cr-006", title: "Weak Hero", thumbName: "thumb_weakhero",
                         videoFileName: "clip_weakhero.mp4")
            ]
            
        case "Top 10 TV Shows in South Korea Today":
            return [
                VideoItem(id: "top-001", title: "Queen of Tears", thumbName: "thumb_queen",
                         videoFileName: "clip_queen.mp4", tags: ["New Episode", "Watch Now"]),
                VideoItem(id: "top-002", title: "Your Majesty", thumbName: "thumb_majesty",
                         videoFileName: "clip_majesty.mp4", tags: ["New Episode", "Watch Now"]),
                VideoItem(id: "top-003", title: "Beyond the Bar", thumbName: "thumb_beyond",
                         videoFileName: "clip_beyond.mp4", tags: ["New Episode", "Watch Now"]),
                VideoItem(id: "top-004", title: "HENJI", thumbName: "thumb_henji",
                         videoFileName: "clip_henji.mp4", tags: ["Recently Added"]),
                VideoItem(id: "top-005", title: "Wednesday", thumbName: "thumb_wednesday2",
                         videoFileName: "clip_wednesday2.mp4", tags: ["New Episodes"]),
                VideoItem(id: "top-006", title: "Demon Slayer", thumbName: "thumb_demon",
                         videoFileName: "clip_demon.mp4")
            ]
            
        case "K-Dramas":
            return [
                VideoItem(id: "kd-001", title: "Beyond the Bar", thumbName: "thumb_beyondbar",
                         videoFileName: "clip_beyondbar.mp4", tags: ["New Episodes", "Watch Now"]),
                VideoItem(id: "kd-002", title: "Chon Appetit: Your Majesty", thumbName: "thumb_chon",
                         videoFileName: "clip_chon.mp4", tags: ["New Episodes", "Watch Now"]),
                VideoItem(id: "kd-003", title: "When Life Gives You Tangerines", thumbName: "thumb_tangerines",
                         videoFileName: "clip_tangerines.mp4"),
                VideoItem(id: "kd-004", title: "The Winning Try", thumbName: "thumb_winning",
                         videoFileName: "clip_winning.mp4", tags: ["New Episodes", "Watch Now"]),
                VideoItem(id: "kd-005", title: "The Trauma Code", thumbName: "thumb_trauma",
                         videoFileName: "clip_trauma.mp4"),
                VideoItem(id: "kd-006", title: "Queen of Tears", thumbName: "thumb_queentears",
                         videoFileName: "clip_queentears.mp4", tags: ["New Episodes", "Watch Now"])
            ]
            
        case "Animation":
            return [
                VideoItem(id: "an-001", title: "K-POP Demon Hunters", thumbName: "thumb_kpop",
                         videoFileName: "clip_kpop.mp4"),
                VideoItem(id: "an-002", title: "K-POP Sing-Along", thumbName: "thumb_singalong",
                         videoFileName: "clip_singalong.mp4", tags: ["Recently Added"]),
                VideoItem(id: "an-003", title: "Dragons: Race to the Edge", thumbName: "thumb_dragons",
                         videoFileName: "clip_dragons.mp4"),
                VideoItem(id: "an-004", title: "Arcane", thumbName: "thumb_arcane",
                         videoFileName: "clip_arcane.mp4", tags: ["Emmy Nominee"]),
                VideoItem(id: "an-005", title: "The Haunted House", thumbName: "thumb_haunted",
                         videoFileName: "clip_haunted.mp4"),
                VideoItem(id: "an-006", title: "Catch! Teenieping", thumbName: "thumb_teenieping",
                         videoFileName: "clip_teenieping.mp4")
            ]
            
        case "Japanese Movies & TV":
            return [
                VideoItem(id: "jp-001", title: "Demon Slayer", thumbName: "thumb_demonslayer",
                         videoFileName: "clip_demonslayer.mp4"),
                VideoItem(id: "jp-002", title: "Attack on Titan", thumbName: "thumb_titan",
                         videoFileName: "clip_titan.mp4"),
                VideoItem(id: "jp-003", title: "Solo Leveling", thumbName: "thumb_solo_leveling",
                         videoFileName: "clip_solo_leveling.mp4"),
                VideoItem(id: "jp-004", title: "The Apothecary Diaries", thumbName: "thumb_apothecary",
                         videoFileName: "clip_apothecary.mp4"),
                VideoItem(id: "jp-005", title: "Fragrant Flower", thumbName: "thumb_fragrant",
                         videoFileName: "clip_fragrant.mp4", tags: ["New Episode", "Watch Now"]),
                VideoItem(id: "jp-006", title: "Kaiju No.8", thumbName: "thumb_kaiju",
                         videoFileName: "clip_kaiju.mp4", tags: ["New Episode", "Watch Now"])
            ]
            
        default:
            return []
        }
    }
}

// MARK: - Netflix Thumbnail Component

struct NetflixThumbnail: View {
    let item: VideoItem
    let isFocused: Bool
    let isTopTen: Bool
    let rank: Int
    
    @State private var isHovering: Bool = false
    
    var body: some View {
        ZStack {
            if isTopTen {
                // Top 10 layout with rank number
                HStack(spacing: -20) {
                    // Rank number
                    Text("\(rank + 1)")
                        .font(.system(size: 100, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 4, x: 2, y: 2)
                    
                    // Thumbnail
                    thumbnailImage
                        .frame(width: 140, height: 180)
                }
            } else {
                // Regular thumbnail
                thumbnailImage
                    .frame(width: 240, height: 135)
            }
        }
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeOut(duration: 0.2), value: isFocused)
    }
    
    private var thumbnailImage: some View {
        ZStack(alignment: .bottomLeading) {
            // Background image
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .overlay(
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5))
                )
            
            // Tags overlay
            if let tags = item.tags, !tags.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                    
                    HStack(spacing: 4) {
                        ForEach(tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    tag.contains("New") ? Color.red : Color.clear
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(Color.white, lineWidth: tag.contains("Watch") ? 1 : 0)
                                )
                        }
                    }
                    .padding(6)
                }
            }
            
            // Netflix "N" logo for originals
            if item.title.contains("Wednesday") || item.title.contains("Squid") {
                VStack {
                    HStack {
                        Spacer()
                        Text("N")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.red)
                            .padding(4)
                    }
                    Spacer()
                }
            }
        }
        .cornerRadius(4)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(isFocused ? Color.white : Color.clear, lineWidth: 2)
        )
    }
}
