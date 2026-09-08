import Foundation

/// 敲击节奏：以点击间隔序列（ms）描述一段可回放的波形。
/// 与语义触感（预设/自定义文案）正交，共用 kind 通道传输，payload 自包含
struct Rhythm: Equatable {
    /// 点击之间的间隔，单位毫秒。长度 = 点击数 - 1
    let gaps: [Int]

    static let payloadPrefix = "rhythm:"
    static let maxTaps = 12
    static let minGap = 60
    static let maxGap = 1500

    init?(gaps: [Int]) {
        // 传输层数据不可信：点数、间隔、总时长全部卡死上限
        guard (1...Rhythm.maxTaps - 1).contains(gaps.count),
              gaps.allSatisfy({ (Rhythm.minGap...Rhythm.maxGap).contains($0) }),
              gaps.reduce(0, +) <= 10_000
        else { return nil }
        self.gaps = gaps
    }

    init?(payload: String) {
        guard payload.hasPrefix(Self.payloadPrefix) else { return nil }
        let numbers = payload.dropFirst(Self.payloadPrefix.count)
            .split(separator: ",")
            .compactMap { Int($0) }
        self.init(gaps: numbers)
    }

    var payload: String {
        Self.payloadPrefix + gaps.map(String.init).joined(separator: ",")
    }

    var tapCount: Int { gaps.count + 1 }
    var totalDuration: Int { gaps.reduce(0, +) }

    // 内置节奏
    static let heartbeat = Rhythm(gaps: [140, 320, 140])!
    static let knock = Rhythm(gaps: [180, 180, 180])!
    static let wave = Rhythm(gaps: [420, 320, 240, 160, 100])!

    static let presets: [(name: String, rhythm: Rhythm)] = [
        ("心跳", heartbeat),
        ("敲门", knock),
        ("浪", wave)
    ]
}