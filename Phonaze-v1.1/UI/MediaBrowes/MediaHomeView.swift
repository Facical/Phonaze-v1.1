import SwiftUI
import Combine

struct MediaHomeView: View {
    @EnvironmentObject private var connectivity: ConnectivityManager
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var session: ExperimentSession
    @EnvironmentObject private var focusTracker: FocusTracker

    @StateObject private var repo = LocalMediaRepository()

    // sections
    @State private var currentSectionIndex: Int = 0
    @State private var sectionIDs: [String] = []
    @State private var activeSectionID: String? = nil

    // hero & player
    @State private var heroItem: VideoItem? = nil
    @State private var playItem: VideoItem? = nil
    @State private var showPlayer: Bool = false
    @State private var moreInfoItem: VideoItem? = nil
    @State private var showMoreInfo: Bool = false

    @State private var bag = Set<AnyCancellable>()

    private let logoImageName = "logo_netflix"   // ← 네가 추가한 로고 png 이름

    var body: some View {
        ScrollViewReader { vProxy in
            VStack(spacing: 0) {

                // === Top Nav (fixed) ===
                TopNavBarView(
                    logoImageName: logoImageName,
                    onTapItem: { item in
                        switch item {
                        case .home:
                            withAnimation { vProxy.scrollTo(sectionIDs.first, anchor: .top) }
                        case .newPopular, .tvShows, .movies, .games, .myList, .browseByLanguages:
                            // 연구용 목업: 우선 첫 섹션으로 스크롤만 연결
                            withAnimation { vProxy.scrollTo(sectionIDs.first, anchor: .top) }
                        }
                    },
                    onTapSearch: {
                        // 필요 시 검색 시트 열기 등 구현
                    },
                    onTapProfile: {}
                )

                // === Body (scrollable) ===
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        if let hero = heroItem {
                            HeroBillboardView(
                                item: hero, repo: repo,
                                onPlay: {
                                    playItem = hero; showPlayer = true
                                },
                                onMoreInfo: {
                                    moreInfoItem = hero; showMoreInfo = true
                                }
                            )
                        }

                        LazyVStack(spacing: 26) {
                            ForEach(repo.allSections()) { section in
                                SectionHeaderView(title: section.title)
                                    .id(section.id)
                                    .padding(.horizontal, 16)

                                CategoryRow(
                                    section: section,
                                    focusTracker: focusTracker,
                                    activeSectionID: $activeSectionID
                                )
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(Color.black) // full black like Netflix
            .onAppear {
                if !repo.isLoaded { _ = repo.load() }
                sectionIDs = repo.allSections().map { $0.id }
                heroItem = pickHero()

                connectivity.setFocusTracker(focusTracker)

                NotificationCenter.default.publisher(for: ConnectivityManager.Noti.scrollV)
                    .sink { noti in
                        guard let dy = noti.userInfo?["dy"] as? Double else { return }
                        handleVerticalScrollCommand(dy: dy, proxy: vProxy)
                    }.store(in: &bag)

                session.$phase
                    .removeDuplicates()
                    .sink { phase in
                        guard phase == .play else { return }
                        guard let tid = session.targetID,
                              let item = repo.item(by: tid) else { return }
                        playItem = item; showPlayer = true
                    }
                    .store(in: &bag)
            }
            .onDisappear { bag.removeAll() }
            .sheet(isPresented: $showPlayer) {
                if let item = playItem {
                    LocalPlayerView(item: item, repo: repo, onFinished: {
                        session.nextTrial(); showPlayer = false
                    }, onClose: { showPlayer = false })
                }
            }
            .sheet(isPresented: $showMoreInfo) {
                if let item = moreInfoItem {
                    MoreInfoSheetView(item: item)
                        .presentationDetents([.medium, .large])
                }
            }
        }
    }

    // MARK: helpers

    private func pickHero() -> VideoItem? {
        for s in repo.allSections() {
            if let m = s.items.first(where: { ($0.tags ?? []).contains("hero") }) { return m }
        }
        return repo.allSections().first?.items.first
    }

    private func handleVerticalScrollCommand(dy: Double, proxy: ScrollViewProxy) {
        guard !sectionIDs.isEmpty else { return }
        let step = (dy > 0) ? 1 : -1
        currentSectionIndex = max(0, min(sectionIDs.count - 1, currentSectionIndex + step))
        let targetID = sectionIDs[currentSectionIndex]
        withAnimation(.easeInOut(duration: 0.25)) {
            proxy.scrollTo(targetID, anchor: .top)
        }
        activeSectionID = targetID
    }
}
