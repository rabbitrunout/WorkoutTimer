import SwiftUI
import UserNotifications
import WatchKit

struct ContentView: View {
    @StateObject private var timerManager = TimerManager()
    private let lastPresetKey = "lastSelectedPresetIndex"
    private let lastCustomTimeKey = "lastCustomTimeSeconds"

    // Presets
    let presets: [TimeInterval] = [60, 5*60, 10*60, 20*60, 30*60]
    let presetLabels: [String]   = ["1m","5m","10m","20m","30m"]

    // Track selected preset index
    @State private var selectedPresetIndex: Int = {
        let saved = UserDefaults.standard.object(forKey: "lastSelectedPresetIndex") as? Int
        return saved ?? 1
    }()

    // Custom timer
    @State private var showingCustomTimeSheet = false
    @State private var customMinutes: Int = 1
    @State private var customSeconds: Int = 0

    var body: some View {
        VStack(spacing: 10) {

            // MARK: - Segmented Pills + Custom
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // Preset pills
                    ForEach(0..<presetLabels.count, id: \.self) { idx in
                        Button(action: {
                            withAnimation {
                                selectedPresetIndex = idx
                                timerManager.setDuration(presets[idx])
                                UserDefaults.standard.set(idx, forKey: lastPresetKey)
                            }
                        }) {
                            Text(presetLabels[idx])
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .frame(minWidth: 44)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 10)
                                .background(segmentBackground(for: idx))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    // Custom pill
                    Button(action: {
                        // Load last custom time if exists
                        let lastCustom = UserDefaults.standard.integer(forKey: lastCustomTimeKey)
                        customMinutes = lastCustom / 60
                        customSeconds = lastCustom % 60
                        selectedPresetIndex = presets.count // mark custom selected
                        showingCustomTimeSheet = true
                    }) {
                        Text("Custom")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .frame(minWidth: 44)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(selectedPresetIndex >= presets.count ? Color.accentColor : Color.clear)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().strokeBorder(Color.gray.opacity(0.4), lineWidth: 1)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 6)
            }

            // MARK: - Timer display
            Text(timerManager.formattedRemaining())
                .font(.system(size: 32, weight: .semibold, design: .rounded))

            // MARK: - Progress ring
            ProgressView(value: timerManager.progress)
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.15)
                .frame(width: 78, height: 78)

            // MARK: - Controls
            HStack(spacing: 10) {
                Button(action: { timerManager.toggle() }) {
                    Label(timerManager.isRunning ? "Pause" : "Start",
                          systemImage: timerManager.isRunning ? "pause.fill" : "play.fill")
                }
                .buttonStyle(.borderedProminent)

                Button(action: { timerManager.reset() }) {
                    Label("Reset", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .sheet(isPresented: $showingCustomTimeSheet) {
            VStack(spacing: 12) {
                Text("Custom Timer")
                    .font(.headline)

                HStack(spacing: 16) {
                    // Minutes Picker
                    VStack {
                        Text("Min")
                            .font(.caption2)
                        Picker("", selection: $customMinutes) {
                            ForEach(0..<121) { i in
                                Text("\(i)").tag(i)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 50, height: 80)
                        .clipped()
                    }

                    // Seconds Picker
                    VStack {
                        Text("Sec")
                            .font(.caption2)
                        Picker("", selection: $customSeconds) {
                            ForEach(0..<60) { i in
                                Text("\(i)").tag(i)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 50, height: 80)
                        .clipped()
                    }
                }

                HStack(spacing: 12) {
                    Button("Set Timer") {
                        showingCustomTimeSheet = false
                        let totalSeconds = TimeInterval(customMinutes * 60 + customSeconds)
                        timerManager.setDuration(totalSeconds)
                        UserDefaults.standard.set(totalSeconds, forKey: lastCustomTimeKey)
                        selectedPresetIndex = presets.count // mark custom selected
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Cancel") {
                        showingCustomTimeSheet = false
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .onAppear {
            // Apply last-used preset or custom timer
            if selectedPresetIndex < presets.count {
                timerManager.setDuration(presets[selectedPresetIndex])
            } else {
                let lastCustom = UserDefaults.standard.integer(forKey: lastCustomTimeKey)
                timerManager.setDuration(TimeInterval(lastCustom))
            }
            requestNotificationPermissionIfNeeded()
        }
    }

    // MARK: - Helpers

    private func segmentBackground(for index: Int) -> some View {
        ZStack {
            if selectedPresetIndex == index {
                Capsule().fill(Color.accentColor)
            } else {
                Capsule()
                    .strokeBorder(Color.gray.opacity(0.4), lineWidth: 1)
                    .background(Capsule().fill(Color.clear))
            }
        }
    }

    private func requestNotificationPermissionIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus != .authorized else { return }
            center.requestAuthorization(options: [.alert, .sound]) { _,_ in }
        }
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
