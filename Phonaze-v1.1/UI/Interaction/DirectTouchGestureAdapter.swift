import SwiftUI

public struct DirectTouchGestureAdapter: View {
    public init() {}

    public var body: some View {
        InteractionOverlay(mode: .directTouch)
    }
}
