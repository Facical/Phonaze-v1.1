import SwiftUI

struct PlatformPickerView: View {
    let onPick: (StreamingPlatform) -> Void
    var onBack: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: 24) {
            HStack {
                if let onBack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
                Spacer()
            }
            .font(.headline)
            .opacity(onBack == nil ? 0 : 1)

            Text("Select Platform")
                .font(.largeTitle).bold()
            Text("Please choose a platform before the experiment.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                ForEach(StreamingPlatform.allCases) { p in
                    Button {
                        onPick(p)
                    } label: {
                        VStack(spacing: 12) {
                            Image(p.assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120, height: 120)
                                .padding(14)
                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))

                            Text(p.title)
                                .font(.title3).bold()
                            Text(p.subtitle)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(18)
                        .frame(minWidth: 260)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                        )
                        .shadow(radius: 10, y: 6)
                    }
                }
            }
            .padding(.top, 8)

            Spacer(minLength: 12)
        }
        .padding(24)
        .background(Color.black.opacity(0.9).ignoresSafeArea())
    }
}
