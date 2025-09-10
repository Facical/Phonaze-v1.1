import SwiftUI

struct InteractionModePicker: View {
    @Binding var mode: InteractionMode
    var onChange: ((InteractionMode) -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Text("Interaction").font(.headline)
            Picker("", selection: $mode) {
                Text("Direct Touch").tag(InteractionMode.directTouch)
                Text("Pinch").tag(InteractionMode.pinch)
                Text("Phonaze").tag(InteractionMode.phonaze)
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 380)
        }
        .padding(12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onChange(of: mode) { _, new in onChange?(new) }
    }
}
