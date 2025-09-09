// UI/Player/LocalPlayerView.swift
import SwiftUI
import AVKit

/// Simple local video player for a VideoItem.
/// - Resolves local URL via LocalMediaRepository
/// - Autoplays on appear
/// - Shows minimal chrome with Close / Continue buttons
struct LocalPlayerView: View {
    let item: VideoItem
    @ObservedObject var repo: LocalMediaRepository
    var onFinished: (() -> Void)? = nil
    var onClose: (() -> Void)? = nil

    @State private var player: AVPlayer? = nil
    @State private var endObserver: Any?

    var body: some View {
        VStack(spacing: 12) {
            Text(item.title)
                .font(.headline)
                .padding(.top, 8)

            if let p = player {
                VideoPlayer(player: p)
                    .frame(minHeight: 280)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.2))
                        .frame(minHeight: 280)
                    Text("Video not found").foregroundStyle(.secondary)
                }
            }

            HStack(spacing: 12) {
                Button {
                    onClose?()
                } label: {
                    Label("Close", systemImage: "xmark.circle.fill")
                }

                Spacer()

                Button {
                    onFinished?()
                } label: {
                    Label("Continue", systemImage: "arrow.forward.circle.fill")
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal)

            Spacer(minLength: 8)
        }
        .padding(16)
        .onAppear(perform: prepare)
        .onDisappear {
            player?.pause()
            if let obs = endObserver {
                NotificationCenter.default.removeObserver(obs)
            }
        }
    }

    private func prepare() {
        guard let url = repo.videoURL(for: item) else { return }
        let p = AVPlayer(url: url)
        player = p
        // observe end
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: p.currentItem,
            queue: .main
        ) { _ in
            onFinished?()
        }
        p.play()
    }
}
