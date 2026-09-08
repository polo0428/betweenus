import Foundation
#if os(watchOS)
import WatchKit
#endif

#if os(watchOS)
/// 节奏回放引擎。
/// 方案 A（默认）：按间隔时序播放 WKHapticType.click——精度受系统调度限制（±20~40ms），
///   但零资源成本、立即可用，适合快速验证"节奏感是否成立"。
/// 方案 B（预留）：play(_: Data:) 播放自定义 haptic 文件——精度高、可表达强弱，
///   需要预先生成 .hud/.click 资源，作为 A 验证通过后的增强路径。
@MainActor
final class RhythmEngine {
    static let shared = RhythmEngine()

    enum Scheme: String, CaseIterable {
        case sequential = "A 时序click"
        case hapticFile = "B haptic文件"
    }

    /// 方案开关，RhythmLab 调试界面可切换对比
    var scheme: Scheme = .sequential

    private var playbackTask: Task<Void, Never>?

    var isPlaying: Bool { playbackTask != nil }

    func play(_ rhythm: Rhythm) {
        stop()
        switch scheme {
        case .sequential:
            playbackTask = Task { await playSequential(rhythm) }
        case .hapticFile:
            playbackTask = Task { await playHapticFile(rhythm) }
        }
    }

    func stop() {
        playbackTask?.cancel()
        playbackTask = nil
    }

    /// 方案 A：每次间隔后播放一次 click
    private func playSequential(_ rhythm: Rhythm) async {
        for gap in rhythm.gaps {
            try? await Task.sleep(nanoseconds: UInt64(gap) * 1_000_000)
            guard !Task.isCancelled else { return }
            WKInterfaceDevice.current().play(.click)
        }
        playbackTask = nil
    }

    /// 方案 B：自定义 haptic 文件播放。资源未接入时退回方案 A 行为。
    /// TODO(spike): 用 haptic file generator 生成按 gaps 编排的 .click 资源，
    /// 挂到 Watch target 后替换此处的 fallback。
    private func playHapticFile(_ rhythm: Rhythm) async {
        WKInterfaceDevice.current().play(.click)
        for gap in rhythm.gaps {
            try? await Task.sleep(nanoseconds: UInt64(gap) * 1_000_000)
            guard !Task.isCancelled else { return }
            WKInterfaceDevice.current().play(.click)
        }
        playbackTask = nil
    }
}

/// 节奏录制器：用户点按采样，点击间隔即节奏。
@MainActor
final class RhythmRecorder: ObservableObject {
    @Published private(set) var gaps: [Int] = []
    @Published private(set) var isRecording = false

    private var lastTapAt: Date?
    private var firstTapAt: Date?

    var draft: Rhythm? { Rhythm(gaps: gaps) }

    func tap() {
        let now = Date()
        if let last = lastTapAt {
            let ms = Int(now.timeIntervalSince(last) * 1000)
            // 超过 maxGap 视为新一轮的开始，而非超长间隔
            guard ms <= Rhythm.maxGap else {
                reset()
                isRecording = true
                firstTapAt = now
                lastTapAt = now
                return
            }
            guard gaps.count < Rhythm.maxTaps - 1 else { return }
            gaps.append(max(ms, Rhythm.minGap))
        } else {
            isRecording = true
            firstTapAt = now
        }
        lastTapAt = now
    }

    func reset() {
        gaps = []
        lastTapAt = nil
        firstTapAt = nil
        isRecording = false
    }
}
#endif