import SwiftUI

struct ResearchDisclaimerView: View {
    var onConfirm: () -> Void
    var onCancel: () -> Void = {}
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.largeTitle)
                    .foregroundStyle(.yellow)
                Text("Research Study Notice")
                    .font(.title2).bold()
                Spacer()
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            
            // Content
            VStack(alignment: .leading, spacing: 16) {
                Text("Important Information")
                    .font(.headline)
                
                Text("This is a custom mock streaming interface created solely for academic research purposes. It is not affiliated with, endorsed by, or connected to Netflix or any other streaming service.")
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                
                Text("• All content shown is simulated\n• No actual streaming occurs\n• Data collected is for research only\n• Your privacy is protected")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
                
                Text("By clicking 'I Understand', you acknowledge this is a research prototype.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            
            Divider()
            
            // Buttons
            HStack(spacing: 12) {
                Button("Cancel") {
                    onCancel()
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("I Understand") {
                    onConfirm()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
        }
        .frame(maxWidth: 600)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(16)
    }
}
