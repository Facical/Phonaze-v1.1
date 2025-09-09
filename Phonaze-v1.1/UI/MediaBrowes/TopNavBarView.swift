import SwiftUI

enum TopNavItem: String, CaseIterable {
    case home = "Home"
    case tvShows = "TV Shows"
    case movies = "Movies"
    case games = "Games"
    case newPopular = "New & Popular"
    case myList = "My List"
    case browseByLanguages = "Browse by Languages"
}

/// Netflix-like top navigation bar
struct TopNavBarView: View {
    let logoImageName: String                 // e.g., "logo_netflix" (png in Assets)
    var onTapItem: ((TopNavItem) -> Void)?    // optional callbacks
    var onTapSearch: (() -> Void)?            // optional
    var onTapProfile: (() -> Void)?           // optional

    var body: some View {
        HStack(spacing: 16) {
            // Logo
            Image(logoImageName)
                .resizable()
                .scaledToFit()
                .frame(height: 26)
                .padding(.leading, 12)

            // Center menu
            HStack(spacing: 18) {
                ForEach(TopNavItem.allCases, id: \.self) { item in
                    Button {
                        onTapItem?(item)
                    } label: {
                        Text(item.rawValue)
                            .font(.callout).bold()
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            // Right icons
            HStack(spacing: 14) {
                Button { onTapSearch?() } label: { Image(systemName: "magnifyingglass") }
                    .buttonStyle(.plain)

                Text("Kids")
                    .font(.callout).bold()

                Button {} label: { Image(systemName: "bell") }
                    .buttonStyle(.plain)

                Button { onTapProfile?() } label: {
                    Circle().fill(.white).frame(width: 22, height: 22) // placeholder avatar
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 12)
        }
        .foregroundStyle(.white)
        .frame(height: 56)
        .background(
            // subtle blur bar
            Color.black.opacity(0.85).overlay(Divider().opacity(0.15), alignment: .bottom)
        )
    }
}
