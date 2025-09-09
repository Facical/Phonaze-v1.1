import SwiftUI

public struct PinchGestureAdapter: View {
    public init() {}

    public var body: some View {
        InteractionOverlay(mode: .pinch)
    }
}
