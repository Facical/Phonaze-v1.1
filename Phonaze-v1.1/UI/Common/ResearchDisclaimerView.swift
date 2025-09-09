import SwiftUI

/// Research disclaimer gate shown before entering the media browser.
struct ResearchDisclaimerView: View {
    var onConfirm: () -> Void
    var onCancel: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(.yellow)
                Text("Prototype Notice")
                    .font(.title3).bold()
                Spacer()
            }

            // 요구한 문구를 "작은 텍스트"로 표기
            Text("[Prototype] This is a custom mock streaming UI for research; not affiliated with any brand.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 8)

            HStack {
                Button("Cancel") { onCancel() }
                Spacer()
                Button("OK") { onConfirm() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        // visionOS에서도 잘 보이도록 기본 시트 높이
        .presentationDetents([.medium, .large])
    }
}
