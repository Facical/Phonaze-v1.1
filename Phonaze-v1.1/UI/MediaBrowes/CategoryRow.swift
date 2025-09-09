import SwiftUI
import Combine

/// One horizontal row with thumbnails.
/// - Highlights focused card (from gaze)
/// - Responds to iPhone horizontal scroll when this row is "active"
struct CategoryRow: View {
    let section: SectionModel
    @ObservedObject var focusTracker: FocusTracker

    // Parent tells which row is currently "active" (last hovered one)
    @Binding var activeSectionID: String?

    @State private var currentIndex: Int = 0
    @State private var bag = Set<AnyCancellable>()

    var body: some View {
        ScrollViewReader { hProxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(Array(section.items.enumerated()), id: \.1.id) { (idx, item) in
                        ThumbnailCard(
                            item: item,
                            isFocused: focusTracker.currentFocusedID == item.id
                        ) {
                            // onHoverIn callback from card
                            activeSectionID = section.id
                        }
                        .id(item.id)
                        .onChange(of: focusTracker.currentFocusedID) { _ in
                            // When focus changes to an item in this row, auto-center it a bit
                            guard activeSectionID == section.id else { return }
                            guard focusTracker.currentFocusedID == item.id else { return }
                            centerOn(itemID: item.id, proxy: hProxy)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(maxHeight: 220)
            .onAppear {
                // subscribe to horizontal scroll notifications
                NotificationCenter.default.publisher(for: ConnectivityManager.Noti.scrollH)
                    .sink { noti in
                        guard activeSectionID == section.id else { return }
                        guard let dx = noti.userInfo?["dx"] as? Double else { return }
                        scrollBy(delta: dx > 0 ? 1 : -1, proxy: hProxy)
                    }
                    .store(in: &bag)
            }
            .onDisappear { bag.removeAll() }
        }
    }

    // MARK: - Programmatic scroll helpers

    private func scrollBy(delta: Int, proxy: ScrollViewProxy) {
        guard !section.items.isEmpty else { return }
        currentIndex = max(0, min(section.items.count - 1, currentIndex + delta))
        let id = section.items[currentIndex].id
        withAnimation(.easeInOut(duration: 0.2)) {
            proxy.scrollTo(id, anchor: .center)
        }
    }

    private func centerOn(itemID: String, proxy: ScrollViewProxy) {
        withAnimation(.easeInOut(duration: 0.18)) {
            proxy.scrollTo(itemID, anchor: .center)
        }
        if let idx = section.items.firstIndex(where: { $0.id == itemID }) {
            currentIndex = idx
        }
    }
}
