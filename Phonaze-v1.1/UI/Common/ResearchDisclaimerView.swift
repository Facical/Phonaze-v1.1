import SwiftUI

struct ResearchDisclaimerView: View {
    var onConfirm: () -> Void
    var onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("Research Disclaimer")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.top, 40)
                .padding(.bottom, 20)
            
            // Content Container
            VStack(spacing: 24) {
                // Warning Icon and Title
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.yellow)
                    
                    Text("Research Study Notice")
                        .font(.title2)
                        .fontWeight(.semibold)
                }
                
                // Important Information Section
                VStack(alignment: .leading, spacing: 20) {
                    Text("Important Information")
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    Text("This is a custom mock streaming interface created solely for academic research purposes. It is not affiliated with, endorsed by, or connected to Netflix or any other streaming service.")
                        .font(.body)
                        .foregroundColor(.primary.opacity(0.9))
                    
                    // Bullet Points
                    VStack(alignment: .leading, spacing: 12) {
                        bulletPoint("All content shown is simulated")
                        bulletPoint("No actual streaming occurs")
                        bulletPoint("Data collected is for research only")
                        bulletPoint("Your privacy is protected")
                    }
                    .padding(.vertical, 8)
                    
                    Text("By clicking 'I Understand', you acknowledge this is a research prototype.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .italic()
                }
                .padding(.horizontal, 30)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.gray.opacity(0.1))
                )
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 20) {
                Button(action: onCancel) {
                    Text("Cancel")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.gray.opacity(0.2))
                        )
                }
                
                Button(action: onConfirm) {
                    Text("I Understand")
                        .font(.headline)
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                        )
                }
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: 600) // Limit width for better readability
        .background(Color.black.opacity(0.95))
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("•")
                .font(.headline)
                .foregroundColor(.yellow)
            Text(text)
                .font(.body)
                .foregroundColor(.primary.opacity(0.9))
            Spacer()
        }
    }
}
