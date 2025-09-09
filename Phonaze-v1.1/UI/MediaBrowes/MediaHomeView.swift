// Phonaze-v1.1/UI/MediaBrowse/MediaHomeView.swift
import SwiftUI
import Combine
import AVKit

struct MediaHomeView: View {
    @EnvironmentObject private var connectivity: ConnectivityManager
    @EnvironmentObject private var gameState: GameState
    @EnvironmentObject private var session: ExperimentSession
    @EnvironmentObject private var focusTracker: FocusTracker
    
    @StateObject private var repo = LocalMediaRepository()
    
    // Navigation & Selection
    @State private var currentSectionIndex: Int = 0
    @State private var activeSectionID: String? = nil
    @State private var selectedItem: VideoItem? = nil
    
    // Hero Section
    @State private var heroItem: VideoItem? = nil
    @State private var heroPlayer: AVPlayer? = nil
    
    // Modal States
    @State private var showPlayer: Bool = false
    @State private var playItem: VideoItem? = nil
    @State private var showMoreInfo: Bool = false
    @State private var moreInfoItem: VideoItem? = nil
    
    @State private var hasShownDisclaimer = false
    @State private var showingDisclaimer = true
    
    @State private var bag = Set<AnyCancellable>()
    
    // Netflix-like sections
    private let netflixSections = [
        "Critically Acclaimed TV Shows",
        "Top 10 TV Shows in South Korea Today",
        "K-Dramas",
        "Animation",
        "Japanese Movies & TV"
    ]
    
    var body: some View {
        if showingDisclaimer && !hasShownDisclaimer {
            // Disclaimer를 전체 화면으로 표시
            ResearchDisclaimerView(
                onConfirm: {
                    hasShownDisclaimer = true
                    showingDisclaimer = false
                    
                    // Disclaimer 확인 후 초기 설정
                    setupExperiment()
                    loadContent()
                    subscribeToMessages()
                },
                onCancel: {
                    // Cancel 시 이전 화면으로 돌아가기
                    // Navigation pop이 필요한 경우 처리
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.8))
        } else {
            
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollViewReader { vProxy in
                    VStack(spacing: 0) {
                        // Top Navigation Bar
                        NetflixNavBar()
                        
                        ScrollView(.vertical, showsIndicators: false) {
                            VStack(spacing: 0) {
                                // Hero Section with Featured Content
                                if let hero = heroItem {
                                    NetflixHeroView(
                                        item: hero,
                                        player: $heroPlayer,
                                        onPlay: {
                                            playItem = hero
                                            showPlayer = true
                                        },
                                        onMoreInfo: {
                                            moreInfoItem = hero
                                            showMoreInfo = true
                                        }
                                    )
                                    .frame(height: 500)
                                }
                                
                                // Content Sections
                                LazyVStack(spacing: 30) {
                                    ForEach(Array(netflixSections.enumerated()), id: \.offset) { index, sectionTitle in
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text(sectionTitle)
                                                .font(.title2)
                                                .bold()
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 50)
                                            
                                            NetflixCategoryRow(
                                                sectionID: "section-\(index)",
                                                sectionTitle: sectionTitle,
                                                focusTracker: focusTracker,
                                                activeSectionID: $activeSectionID,
                                                onSelectItem: { item in
                                                    // Handle selection through tap
                                                    handleItemSelection(item)
                                                }
                                            )
                                            .id("section-\(index)")
                                        }
                                    }
                                }
                                .padding(.vertical, 20)
                            }
                        }
                    }
                }
            }
            .onAppear {
                setupExperiment()
                loadContent()
                subscribeToMessages()
            }
            .onDisappear {
                bag.removeAll()
                heroPlayer?.pause()
            }
            .sheet(isPresented: $showPlayer) {
                if let item = playItem {
                    NetflixPlayerView(
                        item: item,
                        onClose: {
                            showPlayer = false
                            // Notify experiment session if in browse phase
                            if session.phase == .play {
                                session.nextTrial()
                            }
                        }
                    )
                }
            }
            .sheet(isPresented: $showMoreInfo) {
                if let item = moreInfoItem {
                    NetflixInfoSheet(item: item)
                }
            }
    }
}
    
    // MARK: - Setup Methods
    
    private func setupExperiment() {
        connectivity.setFocusTracker(focusTracker)
        gameState.startMediaTask()
    }
    
    private func loadContent() {
        // Load catalog
        if !repo.isLoaded {
            _ = repo.load()
        }
        
        // Set hero item
        if let firstSection = repo.allSections().first,
           let firstItem = firstSection.items.first {
            heroItem = firstItem
            setupHeroPlayer()
        }
    }
    
    private func setupHeroPlayer() {
        guard let hero = heroItem,
              let url = repo.videoURL(for: hero) else { return }
        
        heroPlayer = AVPlayer(url: url)
        heroPlayer?.isMuted = true
        heroPlayer?.play()
        
        // Loop video
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: heroPlayer?.currentItem,
            queue: .main
        ) { _ in
            self.heroPlayer?.seek(to: .zero)
            self.heroPlayer?.play()
        }
    }
    
    private func subscribeToMessages() {
        // Listen for TAP messages from iPhone
        NotificationCenter.default.publisher(for: ConnectivityManager.Noti.tap)
            .sink { _ in
                handleTapSelection()
            }
            .store(in: &bag)
        
        // Listen for scroll messages
        NotificationCenter.default.publisher(for: ConnectivityManager.Noti.scrollV)
            .sink { notification in
                if let dy = notification.userInfo?["dy"] as? Double {
                    handleVerticalScroll(dy)
                }
            }
            .store(in: &bag)
    }
    
    // MARK: - Interaction Handlers
    
    private func handleItemSelection(_ item: VideoItem) {
        selectedItem = item
        
        // Check if this matches experiment target
        if let targetID = session.targetID,
           item.id == targetID {
            session.confirmSelectionWithCurrentFocus()
            
            // Play the item
            playItem = item
            showPlayer = true
        }
    }
    
    private func handleTapSelection() {
        // Use current focused item
        if let focusedID = focusTracker.currentFocusedID,
           let item = repo.item(by: focusedID) {
            handleItemSelection(item)
        }
    }
    
    private func handleVerticalScroll(_ dy: Double) {
        // Scroll between sections
        if dy > 0 {
            currentSectionIndex = min(currentSectionIndex + 1, netflixSections.count - 1)
        } else {
            currentSectionIndex = max(currentSectionIndex - 1, 0)
        }
        activeSectionID = "section-\(currentSectionIndex)"
    }
}

// MARK: - Netflix Navigation Bar

struct NetflixNavBar: View {
    var body: some View {
        HStack(spacing: 30) {
            // Netflix Logo (red text placeholder)
            Text("NETFLIX")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.red)
                .padding(.leading, 50)
            
            // Navigation Items
            Group {
                Text("Home")
                Text("TV Shows")
                Text("Movies")
                Text("New & Popular")
                Text("My List")
                Text("Browse by Languages")
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            // Right side icons
            HStack(spacing: 20) {
                Image(systemName: "magnifyingglass")
                Text("Kids")
                Image(systemName: "bell")
                Image(systemName: "person.crop.circle")
            }
            .font(.system(size: 16))
            .foregroundColor(.white)
            .padding(.trailing, 50)
        }
        .frame(height: 60)
        .background(Color.black.opacity(0.95))
    }
}

// MARK: - Netflix Hero View

struct NetflixHeroView: View {
    let item: VideoItem
    @Binding var player: AVPlayer?
    var onPlay: () -> Void
    var onMoreInfo: () -> Void
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Background video or image
            if let player = player {
                VideoPlayer(player: player)
                    .disabled(true)
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.8)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
            } else {
                Image(item.thumbName)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .overlay(
                        LinearGradient(
                            colors: [.clear, .black.opacity(0.8)],
                            startPoint: .center,
                            endPoint: .bottom
                        )
                    )
            }
            
            // Content overlay
            VStack(alignment: .leading, spacing: 16) {
                // TOP 10 Badge
                HStack(spacing: 8) {
                    Text("TOP")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.red)
                    Text("10")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.6))
                .cornerRadius(4)
                
                // Title
                Text(item.title)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                
                // Description
                if let overview = item.overview {
                    Text(overview)
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(3)
                        .frame(maxWidth: 500)
                }
                
                // Buttons
                HStack(spacing: 16) {
                    Button(action: onPlay) {
                        HStack {
                            Image(systemName: "play.fill")
                            Text("Play")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.white)
                        .cornerRadius(4)
                    }
                    
                    Button(action: onMoreInfo) {
                        HStack {
                            Image(systemName: "info.circle")
                            Text("More Info")
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(4)
                    }
                }
            }
            .padding(.leading, 50)
            .padding(.bottom, 40)
        }
    }
}
