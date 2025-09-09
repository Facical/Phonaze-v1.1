import SwiftUI

struct SectionHeaderView: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.title3).bold()
            Spacer()
        }
        .padding(.top, 6)
    }
}
