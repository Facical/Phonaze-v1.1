import SwiftUI

struct ConnectionView: View {
    @EnvironmentObject var connectivity: ConnectivityManager

    /// Close/return callback (e.g., return route to .start in ContentView)
    var onDone: (() -> Void)? = nil

    @State private var autoDismissWork: DispatchWorkItem?

    var body: some View {
        VStack(spacing: 24) {
            header

            if connectivity.isConnected {
                Image(systemName: "iphone.gen3.radiowaves.left.and.right.circle.fill")
                    .font(.system(size: 100))
                    .foregroundStyle(.green)
                Text("iPhone Connection Successful").font(.title).bold()
                Text(connectivity.connectedPeerName ?? "Connected")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button("Disconnect") { connectivity.stop() }
                        .buttonStyle(.bordered)
                    Button("Done") { onDone?() }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.6)
                Text("Please connect your iPhone").font(.title2).bold()
                Text("iPhone app and ‘Vision Pro  Connect’ tap.")
                    .font(.callout).foregroundStyle(.secondary)

                HStack(spacing: 12) {
                    Button("Start Connection Wait") { connectivity.start() }
                        .buttonStyle(.borderedProminent)
                    Button("Stop") { connectivity.stop() }
                        .buttonStyle(.bordered)
                }
            }

            Spacer()
        }
        .padding(24)
        .navigationTitle("Connection")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let onDone {
                    Button("Close") { onDone() }
                }
            }
        }
        // Start advertisement when app comes in (safe even if already started)
        .task { connectivity.start() }
        // Auto close after some delay when connected (optional)
        .onChange(of: connectivity.isConnected) { _, connected in
            autoDismissWork?.cancel()
            guard connected, let onDone else { return }
            let work = DispatchWorkItem { onDone() }
            autoDismissWork = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2, execute: work)
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(connectivity.isConnected ? Color.green : Color.red)
                .frame(width: 10, height: 10)
            Text(connectivity.isConnected
                 ? "Connected\(connectivity.connectedPeerName.map { " · \($0)" } ?? "")"
                 : "Not Connected")
                .font(.footnote)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}
