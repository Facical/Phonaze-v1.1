import SwiftUI

struct MoreInfoSheetView: View {
    let item: VideoItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Image(item.thumbName)
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(height: 160)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Text(item.title)
                    .font(.title2).bold()

                if let overview = item.overview, !overview.isEmpty {
                    Text(overview)
                        .foregroundStyle(.secondary)
                } else {
                    Text("No synopsis provided.")
                        .foregroundStyle(.secondary)
                }

                if let tags = item.tags, !tags.isEmpty {
                    HStack { ForEach(tags, id: \.self) { tag in TagPill(tag) } }
                }
                Spacer(minLength: 8)
            }
            .padding(18)
        }
    }

    @ViewBuilder private func TagPill(_ t: String) -> some View {
        Text(t.uppercased())
            .font(.caption).bold()
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
    }
}
