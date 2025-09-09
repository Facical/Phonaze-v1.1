import SwiftUI

struct ThumbnailCard: View {
    let item: VideoItem
    let isFocused: Bool
    var onHoverIn: () -> Void

    @EnvironmentObject private var connectivity: ConnectivityManager
    @EnvironmentObject private var focusTracker: FocusTracker

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Image(item.thumbName)
                .resizable()
                .aspectRatio(16/9, contentMode: .fill)
                .frame(width: 260, height: 146)
                .clipped()
                .overlay(LinearGradient(colors: [.clear, .black.opacity(0.55)],
                                        startPoint: .center, endPoint: .bottom))
                .overlay(topRightBadge, alignment: .topTrailing)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(radius: isFocused ? 10 : 3)

            Text(item.title)
                .font(.subheadline).bold()
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                .padding(10)
        }
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(.white.opacity(0.08)))
        .scaleEffect(isFocused ? 1.06 : 1.0)
        .animation(.easeOut(duration: 0.15), value: isFocused)
        .onHover { inside in
            if inside {
                onHoverIn()
                focusTracker.updateCandidate(id: item.id)
                connectivity.broadcastFocus(item.id)
            }
        }
        .accessibilityLabel(item.title)
    }

    @ViewBuilder private var topRightBadge: some View {
        if (item.tags ?? []).contains("top10") {
            Text("TOP 10")
                .font(.caption2).bold()
                .padding(.vertical, 4)
                .padding(.horizontal, 8)
                .background(Color.red.opacity(0.9))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(8)
        }
    }
}
