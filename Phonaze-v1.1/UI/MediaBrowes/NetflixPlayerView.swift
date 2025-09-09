// Phonaze-v1.1/UI/MediaBrowse/NetflixPlayerView.swift
import SwiftUI
import AVKit

struct NetflixPlayerView: View {
    let item: VideoItem
    var onClose: () -> Void
    
    @StateObject private var repo = LocalMediaRepository()
    @State private var player: AVPlayer?
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack {
                // Player controls bar
                HStack {
                    Button(action: onClose) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Text(item.title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    HStack(spacing: 20) {
                        Image(systemName: "text.bubble")
                        Image(systemName: "speaker.wave.2")
                        Image(systemName: "gearshape")
                    }
                    .foregroundColor(.white)
                }
                .padding()
                
                // Video player
                if let player = player {
                    VideoPlayer(player: player)
                        .ignoresSafeArea()
                } else {
                    Text("Loading...")
                        .foregroundColor(.white)
                }
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private func setupPlayer() {
        _ = repo.load()
        
        // Create sample video URL or use placeholder
        if let url = repo.videoURL(for: item) {
            player = AVPlayer(url: url)
        } else {
            // Use a sample video URL for demo
            if let sampleURL = Bundle.main.url(forResource: "sample", withExtension: "mp4") {
                player = AVPlayer(url: sampleURL)
            }
        }
        
        player?.play()
        
        // Auto-close after video ends
        if let player = player {
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: player.currentItem,
                queue: .main
            ) { _ in
                onClose()
            }
        }
    }
}

// MARK: - Netflix Info Sheet

struct NetflixInfoSheet: View {
    let item: VideoItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 20) {
                // Header with close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Hero image
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .aspectRatio(16/9, contentMode: .fit)
                            .overlay(
                                VStack {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(.white)
                                }
                            )
                            .cornerRadius(8)
                        
                        // Title and match percentage
                        HStack {
                            Text(item.title)
                                .font(.largeTitle)
                                .bold()
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            Text("98% Match")
                                .font(.headline)
                                .foregroundColor(.green)
                        }
                        
                        // Metadata
                        HStack(spacing: 16) {
                            Text("2024")
                            Text("1 Season")
                            Text("HD")
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 2)
                                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                                )
                        }
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                        
                        // Overview
                        Text(item.overview ?? "A gripping story that will keep you on the edge of your seat. Follow the journey of compelling characters through unexpected twists and turns.")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .lineSpacing(4)
                        
                        // Cast & Crew (placeholder)
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Cast")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Actor 1, Actor 2, Actor 3, Actor 4")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        // Genres
                        if let tags = item.tags {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Genres")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                HStack {
                                    ForEach(tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.7))
                                        
                                        if tag != tags.last {
                                            Text("•")
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                    }
                                }
                            }
                        }
                        
                        // More Like This section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("More Like This")
                                .font(.title2)
                                .bold()
                                .foregroundColor(.white)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(0..<6) { _ in
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .aspectRatio(16/9, contentMode: .fit)
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .padding(.top, 20)
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}
