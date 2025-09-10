import SwiftUI

/// 앱 홈 화면.
/// - Media Browsing Task: onSelectMediaBrowsing() 호출 (ContentView에서 디스클레이머 → 플랫폼 선택으로 라우팅)
/// - Scroll / Select / Connection: 필요 시 외부에서 콜백 연결(기본은 no-op)
struct StartView: View {
    @EnvironmentObject private var connectivity: ConnectivityManager

    let onSelectMediaBrowsing: () -> Void
    let onOpenScrollTask: () -> Void
    let onOpenSelectTask: () -> Void
    let onOpenConnection: () -> Void

    /// 기본 이니셜라이저: 미연결 콜백은 no-op
    init(
        onSelectMediaBrowsing: @escaping () -> Void = {},
        onOpenScrollTask: @escaping () -> Void = {},
        onOpenSelectTask: @escaping () -> Void = {},
        onOpenConnection: @escaping () -> Void = {}
    ) {
        self.onSelectMediaBrowsing = onSelectMediaBrowsing
        self.onOpenScrollTask = onOpenScrollTask
        self.onOpenSelectTask = onOpenSelectTask
        self.onOpenConnection = onOpenConnection
    }

    var body: some View {
        ZStack(alignment: .top) {
            // 배경
            Color.black.opacity(0.9).ignoresSafeArea()

            VStack(spacing: 24) {
                header

                // 메인 카드(미디어 브라우징)
                TaskCard(
                    icon: "play.rectangle.on.rectangle",
                    title: "Media Browsing Task",
                    description: "Research Disclaimer → Platform Selection (Netflix/YouTube) → Web Browsing",
                    prominent: true,
                    action: onSelectMediaBrowsing
                )

                // 기타 카드들 (필요 시 콜백 연결)
                HStack(spacing: 18) {
                    TaskCard(
                        icon: "rectangle.and.hand.point.up.left",
                        title: "Select Task",
                        description: "Quantitative Task (kept as is)",
                        action: onOpenSelectTask
                    )
                    TaskCard(
                        icon: "arrow.up.and.down.and.arrow.left.and.right",
                        title: "Scroll Task",
                        description: "Quantitative Task (kept as is)",
                        action: onOpenScrollTask
                    )
                }

                HStack(spacing: 18) {
                    TaskCard(
                        icon: "antenna.radiowaves.left.and.right",
                        title: "Connection",
                        description: connectivity.isConnected
                            ? "Connected: \(connectivity.connectedPeerName ?? "iPhone")"
                            : "Connect iPhone auxiliary controller",
                        action: onOpenConnection
                    )
                    // Extra slot (remove if not needed)
                    TaskCard(
                        icon: "info.circle",
                        title: "About / Logs",
                        description: "Experiment logs & CSV export",
                        action: { /* Connect if needed */ }
                    )
                }

                Spacer(minLength: 12)
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
        }
    }

    // MARK: - Subviews

    private var header: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Phonaze")
                    .font(.largeTitle).bold()
                Text("Vision Pro · Media Interaction Experiments")
                    .font(.callout)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            connectionBadge
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var connectionBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(connectivity.isConnected ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            Text(connectivity.isConnected
                 ? "Connected\(connectivity.connectedPeerName.map { " · \($0)" } ?? "")"
                 : "Not Connected")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.regularMaterial, in: Capsule())
    }
}

private struct TaskCard: View {
    let icon: String
    let title: String
    let description: String
    var prominent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: prominent ? 36 : 28, weight: .semibold))
                    .frame(width: prominent ? 56 : 44, height: prominent ? 56 : 44)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(title).font(prominent ? .title2.bold() : .headline)
                    Text(description)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: prominent ? 100 : 82)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .strokeBorder(.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(radius: prominent ? 14 : 10, y: prominent ? 8 : 6)
        }
        .buttonStyle(.plain)
    }
}
