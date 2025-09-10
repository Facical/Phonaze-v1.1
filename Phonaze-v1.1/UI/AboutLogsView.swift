import SwiftUI

struct AboutLogsView: View {
    @EnvironmentObject var experimentSession: ExperimentSession
    @EnvironmentObject var connectivity: ConnectivityManager
    
    @State private var showingExportAlert = false
    @State private var exportedTrialsURL: URL?
    @State private var exportedEventsURL: URL?
    
    var onBack: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            HStack {
                if let onBack {
                    Button(action: onBack) {
                        Label("Back", systemImage: "chevron.left")
                            .font(.headline)
                    }
                }
                Spacer()
                Text("Experiment Logs & Data")
                    .font(.title2).bold()
                Spacer()
            }
            .padding(.horizontal)
            
            // Connection Status
            connectionStatusCard
            
            // Experiment Info
            experimentInfoCard
            
            // Session Stats
            if experimentSession.phase != .idle {
                sessionStatsCard
            }
            
            // Event Logs Preview
            eventLogsCard
            
            // Export Buttons
            exportButtonsSection
            
            Spacer()
        }
        .padding()
        .background(Color.black.opacity(0.9))
        .alert("Export Complete", isPresented: $showingExportAlert) {
            Button("OK") { }
        } message: {
            Text("CSV files have been exported successfully")
        }
    }
    
    // MARK: - Subviews
    
    private var connectionStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Connection Status", systemImage: "antenna.radiowaves.left.and.right")
                .font(.headline)
            
            HStack {
                Circle()
                    .fill(connectivity.isConnected ? Color.green : Color.red)
                    .frame(width: 12, height: 12)
                Text(connectivity.isConnected
                     ? "Connected to: \(connectivity.connectedPeerName ?? "iPhone")"
                     : "Not Connected")
                Spacer()
            }
            
            if !connectivity.lastReceivedMessage.isEmpty {
                Text("Last Message: \(connectivity.lastReceivedMessage)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var experimentInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Experiment Configuration", systemImage: "gearshape")
                .font(.headline)
            
            LabeledContent(label: "Participant ID", value: experimentSession.config.participantID)
            LabeledContent(label: "Task Type", value: experimentSession.config.taskType)
            LabeledContent(label: "Platform", value: experimentSession.config.platform ?? "Not Set")
            LabeledContent(label: "Interaction Mode", value: experimentSession.config.interactionMode)
            LabeledContent(label: "Goal Trials", value: "\(experimentSession.config.goalTrials)")
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var sessionStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Current Session", systemImage: "chart.bar")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Phase")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(experimentSession.phase.rawValue.capitalized)
                        .font(.title3).bold()
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(experimentSession.successCount) / \(experimentSession.config.goalTrials)")
                        .font(.title3).bold()
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("Errors")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(experimentSession.errorCount)")
                        .font(.title3).bold()
                        .foregroundStyle(experimentSession.errorCount > 0 ? .red : .primary)
                }
            }
            
            if let targetID = experimentSession.targetID {
                Divider()
                LabeledContent(label: "Current Target", value: targetID)
                    .font(.footnote)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var eventLogsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Event Logs", systemImage: "doc.text")
                    .font(.headline)
                Spacer()
                Text("\(experimentSession.logger.eventLogs.count) events")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if experimentSession.logger.eventLogs.isEmpty {
                Text("No events logged yet")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        let recentLogs = Array(experimentSession.logger.eventLogs.suffix(10))
                        ForEach(recentLogs.indices, id: \.self) { index in
                            let event = recentLogs[index]
                            HStack {
                                Text(formatTime(event.timestamp))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 60)
                                
                                Text(event.kind)
                                    .font(.caption)
                                    .bold()
                                
                                if !event.payload.isEmpty {
                                    Text(formatPayload(event.payload))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                
                                Spacer()
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .frame(maxHeight: 150)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    private var exportButtonsSection: some View {
        VStack(spacing: 12) {
            Text("Export Data")
                .font(.headline)
            
            HStack(spacing: 16) {
                // Export Trials CSV
                Button(action: exportTrialsData) {
                    Label("Export Trials CSV", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(experimentSession.logger.trials.isEmpty)
                
                // Export Events CSV
                Button(action: exportEventsData) {
                    Label("Export Events CSV", systemImage: "doc.badge.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(experimentSession.logger.eventLogs.isEmpty)
            }
            
            // Share exported files
            if let trialsURL = exportedTrialsURL {
                ShareLink(item: trialsURL) {
                    Label("Share Trials CSV", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            if let eventsURL = exportedEventsURL {
                ShareLink(item: eventsURL) {
                    Label("Share Events CSV", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            // Session Controls
            Divider()
            
            HStack(spacing: 16) {
                Button("Reset Session") {
                    experimentSession.restart()
                }
                .buttonStyle(.bordered)
                .foregroundStyle(.red)
                
                Button("Start New Session") {
                    experimentSession.startOrContinue()
                }
                .buttonStyle(.borderedProminent)
                .disabled(experimentSession.phase != .idle && experimentSession.phase != .end)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
    
    // MARK: - Helper Functions
    
    private func exportTrialsData() {
        let (trialsURL, _) = experimentSession.exportCSV(exportEvents: false)
        if let url = trialsURL {
            exportedTrialsURL = url
            showingExportAlert = true
        }
    }
    
    private func exportEventsData() {
        let (_, eventsURL) = experimentSession.exportCSV(exportEvents: true)
        if let url = eventsURL {
            exportedEventsURL = url
            showingExportAlert = true
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatPayload(_ payload: [String: String]) -> String {
        payload.map { "\($0.key):\($0.value)" }.joined(separator: ", ")
    }
}

// MARK: - LabeledContent Helper
struct LabeledContent: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .bold()
        }
    }
}
