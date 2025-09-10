import SwiftUI

/// 재사용 가능한 네비게이션 헤더 컴포넌트
struct NavigationHeader: View {
    let title: String
    let showBackButton: Bool
    let onBack: (() -> Void)?
    var rightContent: AnyView? = nil
    
    init(
        title: String = "",
        showBackButton: Bool = true,
        onBack: (() -> Void)? = nil,
        @ViewBuilder rightContent: () -> some View = { EmptyView() }
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.onBack = onBack
        self.rightContent = AnyView(rightContent())
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Back button
            if showBackButton, let onBack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.3))
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                }
                .buttonStyle(.plain)
            }
            
            // Title (center if no back button)
            if !title.isEmpty {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            } else {
                Spacer()
            }
            
            // Right content
            if let rightContent {
                rightContent
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(
            Color.black.opacity(0.5)
                .background(.ultraThinMaterial)
                .ignoresSafeArea()
        )
    }
}
