import SwiftUI
import AVKit

/// Top hero billboard (video-first, image fallback)
struct HeroBillboardView: View {
    let item: VideoItem
    @ObservedObject var repo: LocalMediaRepository
    var onPlay: () -> Void
    var onMoreInfo: () -> Void

    @State private var player: AVPlayer? = nil
    @State private var isMuted: Bool = true
    @State private var endObserver: Any?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            backgroundMedia
                .frame(height: 360)
                .clipped()
                .overlay(gradientOverlay)
                .overlay(topRightBadges, alignment: .topTrailing)

            VStack(alignment: .leading, spacing: 12) {
                Text(item.title)
                    .font(.system(size: 40, weight: .heavy))
                    .shadow(radius: 8)

                HStack(spacing: 10) {
                    Button(action: onPlay) {
                        Label("Play", systemImage: "play.fill")
                            .font(.headline)
                            .foregroundStyle(.black)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 16)
                            .background(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Button(action: onMoreInfo) {
                        Label("More Info", systemImage: "info.circle")
                            .font(.headline)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(.ultraThinMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.leading, 24)
            .padding(.bottom, 24)
        }
        .background(Color.black)
        .onAppear(perform: preparePlayer)
        .onDisappear {
            player?.pause()
            if let obs = endObserver { NotificationCenter.default.removeObserver(obs) }
        }
    }

    // MARK: layers

    @ViewBuilder private var backgroundMedia: some View {
        if let p = player {
            VideoPlayer(player: p)
                .onTapGesture {
                    isMuted.toggle(); p.isMuted = isMuted
                }
        } else {
            Image(item.thumbName)
                .resizable()
                .scaledToFill()
        }
    }

    private var gradientOverlay: some View {
        LinearGradient(
            colors: [Color.black.opacity(0.65), Color.black.opacity(0.25), Color.black.opacity(0.85)],
            startPoint: .top, endPoint: .bottom
        )
        .allowsHitTesting(false)
    }

    private var topRightBadges: some View {
        HStack(spacing: 12) {
            Button {
                isMuted.toggle(); player?.isMuted = isMuted
            } label: {
                Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                    .font(.title3)
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }

            Text(maturityText)
                .font(.headline)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(Color.black.opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding(16)
    }

    private var maturityText: String {
        if let t = item.tags?.first(where: { Int($0) != nil }) { return t }
        return "12"
    }

    private func preparePlayer() {
        guard let url = repo.videoURL(for: item) else { return }
        let p = AVPlayer(url: url)
        p.isMuted = isMuted
        p.play()
        player = p
        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: p.currentItem,
            queue: .main
        ) { _ in
            p.seek(to: .zero); p.play() // loop
        }
    }
}
