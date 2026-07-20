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

    private let presetMinutes = [5, 10, 15, 30, 60, 90]

    @State private var phase: Phase = .work
    @State private var selectedMinutes = 30
    @State private var background: TimerBackground = .white
    @State private var timeRemaining = 30 * 60
    @State private var isRunning = false
    @State private var isMetronomeEnabled = false
    @State private var keepInForeground = false
    @State private var milestoneVolume: MilestoneVolume = .medium
    @State private var completedTickMilestones: Set<Int> = []
    
    var body: some View {
        ZStack {
            background.fill
                .ignoresSafeArea()

            GeometryReader { proxy in
                let timerSize = timerDiameter(for: proxy.size)

                VStack(spacing: 12) {
                    Text(phase.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(background.foreground)

                    ZStack {
                        Circle()
                            .stroke(background.foreground.opacity(0.16), lineWidth: timerLineWidth(for: timerSize))
                        Circle()
                            .trim(from: 0, to: progressValue())
                            .stroke(phase.color, style: StrokeStyle(lineWidth: timerLineWidth(for: timerSize), lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        if isMetronomeEnabled {
                            ForEach([0, 90, 180, 270], id: \.self) { degrees in
                                milestoneMarker(for: timerSize)
                                    .rotationEffect(.degrees(Double(degrees)))
                            }
                        }
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
                        HStack(alignment: .bottom, spacing: 4) {
                            ForEach(MilestoneVolume.allCases) { level in
                                Button {
                                    milestoneVolume = level
                                    playTick()
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
                    }
                }
                .foregroundStyle(background.foreground)
                .colorScheme(background == .black ? .dark : .light)
                }
                .padding(.horizontal, 16)
                .padding(.top, 18)
                .padding(.bottom, 28)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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
        .frame(minWidth: 244, idealWidth: 244, maxWidth: .infinity, minHeight: 360, idealHeight: 360, maxHeight: .infinity)
        .preferredColorScheme(background == .black ? .dark : .light)
        .task(id: isRunning) {
            await runTimer()
        }
    }
    
    func progressValue() -> Double {
        let duration = phase.duration(workDuration: selectedMinutes * 60)
        return Double(duration - timeRemaining) / Double(duration)
    }

    func timerDiameter(for size: CGSize) -> CGFloat {
        let availableDiameter = min(size.width - 48, size.height - 226)
        return min(max(availableDiameter, 136), 520)
    }

    func timerLineWidth(for diameter: CGFloat) -> CGFloat {
        min(max(diameter * 0.07, 12), 28)
    }

    func timerFontSize(for diameter: CGFloat) -> CGFloat {
        min(max(diameter * 0.2, 34), 92)
    }

    func milestoneMarker(for diameter: CGFloat) -> some View {
        let markerHeight = min(max(diameter * 0.045, 8), 18)

        return RoundedRectangle(cornerRadius: max(diameter * 0.004, 1))
            .fill(Color.red.opacity(0.9))
            .frame(width: min(max(diameter * 0.012, 2), 5), height: markerHeight)
            .offset(y: -diameter / 2 + markerHeight / 2)
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
                playElapsedMilestoneTickIfNeeded()
            }

            if timeRemaining == 0 {
                await playCompletionTickIfNeeded()
                isRunning = false
                phase = phase == .work ? .rest : .work
                timeRemaining = phase.duration(workDuration: selectedMinutes * 60)
                completedTickMilestones = []
            }
        }
    }

    func playElapsedMilestoneTickIfNeeded() {
        guard isMetronomeEnabled else {
            return
        }

        let duration = phase.duration(workDuration: selectedMinutes * 60)
        let elapsed = duration - timeRemaining

        for milestone in 1...3 {
            let threshold = duration * milestone / 4

            if elapsed >= threshold && !completedTickMilestones.contains(milestone) {
                completedTickMilestones.insert(milestone)
                playTick()
            }
        }
    }

    func playCompletionTickIfNeeded() async {
        guard isMetronomeEnabled else {
            return
        }

        for tickIndex in 0..<3 {
            guard !Task.isCancelled else {
                return
            }

            playTick()

            if tickIndex < 2 {
                try? await Task.sleep(nanoseconds: 160_000_000)
            }
        }
    }

    func playTick() {
        guard let sound = NSSound(named: "Tink") else {
            return
        }

        sound.volume = milestoneVolume.volume
        sound.play()
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
