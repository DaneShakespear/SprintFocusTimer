//
//  ContentView.swift
//  SprintFocusTimer
//
//  Created by Dane Shakespear on 7/19/26.
//
import SwiftUI
import AppKit

struct MenuBarView: View {
    private enum TimerBackground: String, CaseIterable, Identifiable {
        case white = "White"
        case black = "Black"

        var id: Self { self }

        var fill: Color {
            switch self {
            case .white:
                .white
            case .black:
                .black
            }
        }

        var foreground: Color {
            switch self {
            case .white:
                .black
            case .black:
                .white
            }
        }

        var secondaryForeground: Color {
            switch self {
            case .white:
                .black.opacity(0.6)
            case .black:
                .white.opacity(0.65)
            }
        }
    }

    private enum Phase {
        case work
        case rest

        var title: String {
            switch self {
            case .work:
                "Work"
            case .rest:
                "Rest"
            }
        }

        func duration(workDuration: Int) -> Int {
            switch self {
            case .work:
                workDuration
            case .rest:
                5 * 60
            }
        }

        var color: Color {
            switch self {
            case .work:
                .red
            case .rest:
                .blue
            }
        }
    }

    private enum MilestoneVolume: Int, CaseIterable, Identifiable {
        case soft = 1
        case medium
        case loud
        case full

        var id: Self { self }

        var volume: Float {
            switch self {
            case .soft:
                0.25
            case .medium:
                0.45
            case .loud:
                0.7
            case .full:
                1
            }
        }

        var title: String {
            switch self {
            case .soft:
                "Soft"
            case .medium:
                "Medium"
            case .loud:
                "Loud"
            case .full:
                "Full"
            }
        }
    }

    private let presetMinutes = [1, 5, 10, 15, 30, 60, 90]

    @State private var phase: Phase = .work
    @AppStorage("selectedMinutes") private var selectedMinutes = 30
    @AppStorage("timerBackground") private var background: TimerBackground = .black
    @State private var timeRemaining = 30 * 60
    @State private var isRunning = false
    @AppStorage("isMetronomeEnabled") private var isMetronomeEnabled = false
    @AppStorage("isCompletionAlarmEnabled") private var isCompletionAlarmEnabled = true
    @AppStorage("isVisualAlertEnabled") private var isVisualAlertEnabled = false
    @State private var visualAlertPulse = false
    @AppStorage("keepInForeground") private var keepInForeground = false
    @AppStorage("milestoneVolume") private var milestoneVolume: MilestoneVolume = .medium
    @AppStorage("isFocusBoardOpen") private var isFocusBoardOpen = false
    @AppStorage("focusBoardText") private var focusBoardText = "- Stay on the current task\n- Keep the next action visible\n- Avoid opening unrelated tabs\n- Write down distractions\n- Return to the timer\n- Finish one small step"
    @State private var completedTickMilestones: Set<Int> = []
    
    var body: some View {
        ZStack {
            background.fill
                .ignoresSafeArea()

            GeometryReader { proxy in
                let boardWidth = focusBoardWidth(for: proxy.size)
                let timerWidth = proxy.size.width - (isFocusBoardOpen ? boardWidth + 58 : 0)
                let timerSize = timerDiameter(for: CGSize(width: timerWidth, height: proxy.size.height))

                HStack(spacing: 14) {
                    VStack(spacing: 12) {
                        Text(phase.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(background.foreground)

                        ZStack {
                            Circle()
                                .stroke(background.foreground.opacity(0.16), lineWidth: timerLineWidth(for: timerSize))
                            if isMetronomeEnabled {
                                ForEach([0, 90, 180, 270], id: \.self) { degrees in
                                    milestoneMarker(for: timerSize)
                                        .rotationEffect(.degrees(Double(degrees)))
                                }
                            }
                            Circle()
                                .trim(from: 0, to: progressValue())
                                .stroke(phase.color, style: StrokeStyle(lineWidth: timerLineWidth(for: timerSize), lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            Text(formatTime(timeRemaining))
                                .font(.system(size: timerFontSize(for: timerSize), weight: .bold, design: .monospaced))
                                .foregroundStyle(background.foreground)
                        }
                        .frame(width: timerSize, height: timerSize)
                        .padding(.bottom, 8)

                        HStack(spacing: 8) {
                            Text("Time")
                                .font(.caption)
                                .foregroundStyle(background.secondaryForeground)

                            Picker("Sprint length", selection: $selectedMinutes) {
                                ForEach(presetMinutes, id: \.self) { minutes in
                                    Text("\(minutes) min").tag(minutes)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(width: 98)
                            .labelsHidden()
                            .colorScheme(background == .black ? .dark : .light)
                            .onChange(of: selectedMinutes) {
                                resetTimer()
                            }
                        }

                        HStack(spacing: 8) {
                            Button(isRunning ? "Stop" : "Start") { isRunning.toggle() }
                                .keyboardShortcut(.space, modifiers: [])

                            Button("Reset") { resetTimer() }
                        }
                        .buttonStyle(.bordered)
                        .colorScheme(background == .black ? .dark : .light)

                        HStack(spacing: 8) {
                            Button {
                                isMetronomeEnabled.toggle()
                            } label: {
                                Label(isMetronomeEnabled ? "Milestones on" : "Milestones off", systemImage: "metronome")
                            }
                            .buttonStyle(.bordered)

                            if isMetronomeEnabled {
                                HStack(spacing: 6) {
                                    HStack(alignment: .bottom, spacing: 4) {
                                        ForEach(MilestoneVolume.allCases) { level in
                                            Button {
                                                milestoneVolume = level
                                                previewMilestoneAlert()
                                            } label: {
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(level.rawValue <= milestoneVolume.rawValue ? Color.accentColor : background.foreground.opacity(0.22))
                                                    .frame(width: 8, height: CGFloat(level.rawValue * 5 + 6))
                                            }
                                            .buttonStyle(.plain)
                                            .help("\(level.title) milestone volume")
                                        }
                                    }
                                    .frame(height: 28)
                                    .padding(.horizontal, 6)
                                    .background(background.foreground.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))

                                    Button {
                                        isCompletionAlarmEnabled.toggle()
                                        if isCompletionAlarmEnabled {
                                            Task {
                                                await previewCompletionAlarm()
                                            }
                                        }
                                    } label: {
                                        Image(systemName: isCompletionAlarmEnabled ? "bell.fill" : "bell.slash")
                                            .font(.system(size: 13, weight: .semibold))
                                            .frame(width: 26, height: 26)
                                    }
                                    .buttonStyle(.bordered)
                                    .help(isCompletionAlarmEnabled ? "Timer alarm on" : "Timer alarm off")
                                }
                            }
                        }
                        .foregroundStyle(background.foreground)
                        .colorScheme(background == .black ? .dark : .light)

                        HStack(spacing: 8) {
                            Button {
                                isVisualAlertEnabled.toggle()
                                if isVisualAlertEnabled {
                                    triggerVisualAlert()
                                }
                            } label: {
                                Label(isVisualAlertEnabled ? "Visuals on" : "Visuals off", systemImage: "sparkles")
                            }
                            .buttonStyle(.bordered)
                        }
                        .foregroundStyle(background.foreground)
                        .colorScheme(background == .black ? .dark : .light)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)

                    if isFocusBoardOpen {
                        focusBoard(width: boardWidth)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .animation(.spring(response: 0.32, dampingFraction: 0.88), value: isFocusBoardOpen)
            }
        }
        .overlay(alignment: .topTrailing) {
            Button {
                background = background == .white ? .black : .white
            } label: {
                Image(systemName: background == .white ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(background.foreground)
            .background(background.foreground.opacity(0.1), in: Circle())
            .help(background == .white ? "Switch to dark background" : "Switch to light background")
            .padding(10)
        }
        .overlay(alignment: .trailing) {
            Button {
                isFocusBoardOpen.toggle()
            } label: {
                Image(systemName: isFocusBoardOpen ? "sidebar.right" : "sidebar.right")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 28, height: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(background.foreground)
            .background(background.foreground.opacity(isFocusBoardOpen ? 0.18 : 0.1), in: RoundedRectangle(cornerRadius: 8))
            .help(isFocusBoardOpen ? "Hide focus board" : "Show focus board")
            .padding(.trailing, 10)
        }
        .overlay {
            attentionGlow()
                .opacity(visualAlertPulse ? 1 : 0)
        }
        .overlay(alignment: .topLeading) {
            Button {
                keepInForeground.toggle()
            } label: {
                Image(systemName: keepInForeground ? "pin.fill" : "pin")
                    .font(.system(size: 13, weight: .semibold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .foregroundStyle(background.foreground)
            .background(background.foreground.opacity(keepInForeground ? 0.18 : 0.1), in: Circle())
            .help(keepInForeground ? "Allow other windows in front" : "Keep window in foreground")
            .padding(10)
        }
        .background(WindowLevelAccessor(isAlwaysOnTop: keepInForeground))
        .frame(minWidth: isFocusBoardOpen ? 520 : 270, idealWidth: isFocusBoardOpen ? 520 : 270, maxWidth: .infinity, minHeight: 388, idealHeight: 388, maxHeight: .infinity)
        .preferredColorScheme(background == .black ? .dark : .light)
        .onAppear {
            timeRemaining = phase.duration(workDuration: selectedMinutes * 60)
        }
        .task(id: isRunning) {
            await runTimer()
        }
    }
    
    func progressValue() -> Double {
        let duration = phase.duration(workDuration: selectedMinutes * 60)
        return Double(duration - timeRemaining) / Double(duration)
    }

    func timerDiameter(for size: CGSize) -> CGFloat {
        let availableDiameter = min(size.width - 48, size.height - 258)
        return min(max(availableDiameter, 136), 520)
    }

    func focusBoardWidth(for size: CGSize) -> CGFloat {
        min(max(size.width * 0.34, 210), 280)
    }

    func timerLineWidth(for diameter: CGFloat) -> CGFloat {
        min(max(diameter * 0.07, 12), 28)
    }

    func timerFontSize(for diameter: CGFloat) -> CGFloat {
        min(max(diameter * 0.2, 34), 92)
    }

    func milestoneMarker(for diameter: CGFloat) -> some View {
        let lineWidth = timerLineWidth(for: diameter)
        let markerWidth = min(max(lineWidth * 0.34, 4), 8)
        let markerHeight = lineWidth * 0.9

        return Capsule()
            .fill(Color.blue.opacity(0.95))
            .frame(width: markerWidth, height: markerHeight)
            .offset(y: -diameter / 2 + lineWidth / 2)
    }

    func focusBoard(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Focus board", systemImage: "list.bullet.rectangle")
                    .font(.headline)

                Spacer()

                Button {
                    isFocusBoardOpen = false
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .semibold))
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.plain)
                .help("Close focus board")
            }

            TextEditor(text: $focusBoardText)
                .font(.system(size: 14, weight: .regular, design: .rounded))
                .scrollContentBackground(.hidden)
                .padding(8)
                .frame(minHeight: 176)
                .background(background.fill.opacity(background == .black ? 0.92 : 0.78), in: RoundedRectangle(cornerRadius: 8))
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(background.foreground.opacity(0.16), lineWidth: 1)
                }
        }
        .foregroundStyle(background.foreground)
        .padding(12)
        .frame(width: width, alignment: .topLeading)
        .frame(minHeight: 244, alignment: .topLeading)
        .background(background.foreground.opacity(background == .black ? 0.09 : 0.07), in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .stroke(background.foreground.opacity(0.14), lineWidth: 1)
        }
        .padding(.trailing, 44)
    }

    func attentionGlow() -> some View {
        let primaryOpacity = background == .black ? 0.62 : 0.38
        let secondaryOpacity = background == .black ? 0.42 : 0.24
        let fillOpacity = background == .black ? 0.14 : 0.06

        return RoundedRectangle(cornerRadius: 18)
            .stroke(Color.red.opacity(primaryOpacity), lineWidth: background == .black ? 34 : 24)
            .blur(radius: background == .black ? 26 : 18)
            .overlay {
                RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.red.opacity(secondaryOpacity), lineWidth: background == .black ? 14 : 9)
                    .blur(radius: background == .black ? 14 : 8)
            }
            .background {
                RoundedRectangle(cornerRadius: 18)
                    .fill(Color.red.opacity(fillOpacity))
                    .blur(radius: background == .black ? 48 : 34)
            }
            .padding(background == .black ? 18 : 14)
            .allowsHitTesting(false)
            .animation(.easeInOut(duration: 0.22), value: visualAlertPulse)
    }
    
    func formatTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let secs = seconds % 60
        return "\(minutes):\(secs < 10 ? "0" : "")\(secs)"
    }
    
    func resetTimer() {
        phase = .work
        timeRemaining = phase.duration(workDuration: selectedMinutes * 60)
        completedTickMilestones = []
        isRunning = false
    }

    func runTimer() async {
        while isRunning && !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 1_000_000_000)

            guard isRunning && !Task.isCancelled else {
                return
            }

            if timeRemaining > 0 {
                timeRemaining -= 1
                triggerElapsedMilestoneAlertsIfNeeded()
            }

            if timeRemaining == 0 {
                await triggerCompletionAlerts()
                isRunning = false
                phase = .work
                timeRemaining = phase.duration(workDuration: selectedMinutes * 60)
                completedTickMilestones = []
            }
        }
    }

    func triggerElapsedMilestoneAlertsIfNeeded() {
        let duration = phase.duration(workDuration: selectedMinutes * 60)
        let elapsed = duration - timeRemaining

        for milestone in 1...3 {
            let threshold = duration * milestone / 4

            if elapsed >= threshold && !completedTickMilestones.contains(milestone) {
                completedTickMilestones.insert(milestone)
                triggerMilestoneAlert()
            }
        }
    }

    func triggerMilestoneAlert() {
        if isMetronomeEnabled {
            playTick()
        }

        if isVisualAlertEnabled {
            triggerVisualAlert()
        }
    }

    func triggerCompletionAlerts() async {
        if isVisualAlertEnabled {
            Task {
                await triggerCompletionVisualAlert()
            }
        }

        guard isMetronomeEnabled else {
            return
        }

        if isCompletionAlarmEnabled {
            await playCompletionSound()
        } else {
            playTick()
        }
    }

    func playCompletionSound() async {
        for soundIndex in 0..<3 {
            guard !Task.isCancelled else {
                return
            }

            await playAlarmSound()

            if soundIndex < 2 {
                try? await Task.sleep(nanoseconds: 420_000_000)
            }
        }
    }

    func previewMilestoneAlert() {
        playTick()

        if isVisualAlertEnabled {
            triggerVisualAlert(duration: 900_000_000)
        }
    }

    func previewCompletionAlarm() async {
        if isVisualAlertEnabled {
            Task {
                await triggerCompletionVisualAlert()
            }
        }

        await playCompletionSound()
    }

    func playTick() {
        playSound(named: "Tink", volume: milestoneVolume.volume)
    }

    func playAlarmSound() async {
        let firstSoundPlayed = playSound(named: "Sosumi", volume: 1)
            || playSound(named: "Funk", volume: 1)
            || playSound(named: "Basso", volume: 1)

        try? await Task.sleep(nanoseconds: 95_000_000)

        let secondSoundPlayed = playSound(named: "Glass", volume: 1)
            || playSound(named: "Ping", volume: 1)

        try? await Task.sleep(nanoseconds: 95_000_000)

        let thirdSoundPlayed = playSound(named: "Submarine", volume: 1)
            || playSound(named: "Hero", volume: 1)

        if !firstSoundPlayed && !secondSoundPlayed && !thirdSoundPlayed {
            NSSound.beep()
        }
    }

    @discardableResult
    func playSound(named name: String, volume: Float) -> Bool {
        if let sound = NSSound(named: name) {
            sound.volume = volume
            sound.play()
            return true
        }

        return false
    }

    func triggerVisualAlert(duration: UInt64 = 1_600_000_000) {
        visualAlertPulse = true

        Task {
            try? await Task.sleep(nanoseconds: duration)
            await MainActor.run {
                visualAlertPulse = false
            }
        }
    }

    func triggerCompletionVisualAlert() async {
        for pulseIndex in 0..<3 {
            guard !Task.isCancelled else {
                return
            }

            visualAlertPulse = true
            try? await Task.sleep(nanoseconds: 520_000_000)
            visualAlertPulse = false

            if pulseIndex < 2 {
                try? await Task.sleep(nanoseconds: 180_000_000)
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        MenuBarView()
    }
}

private struct WindowLevelAccessor: NSViewRepresentable {
    let isAlwaysOnTop: Bool

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            updateWindowLevel(for: view)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            updateWindowLevel(for: nsView)
        }
    }

    private func updateWindowLevel(for view: NSView) {
        view.window?.level = isAlwaysOnTop ? .floating : .normal
    }
}
