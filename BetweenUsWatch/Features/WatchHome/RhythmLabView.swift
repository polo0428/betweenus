import SwiftUI

/// 节奏技术验证工作台：录制 → 回放对比 → （调试入口）发给 iPhone 走完整链路
struct RhythmLabView: View {
    @StateObject private var recorder = RhythmRecorder()
    @State private var engine = RhythmEngine.shared
    @State private var lastPayload: String = "—"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                schemePicker
                presetSection
                recordSection
                gapBar
                payloadSection
            }
            .padding(.horizontal, 12)
        }
        .navigationTitle("节奏实验室")
    }

    private var schemePicker: some View {
        Picker("回放方案", selection: $engine.scheme) {
            ForEach(RhythmEngine.Scheme.allCases, id: \.self) { scheme in
                Text(scheme.rawValue).tag(scheme)
            }
        }
        .pickerStyle(.wheel)
        .frame(height: 46)
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("内置节奏")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            ForEach(Rhythm.presets, id: \.name) { preset in
                Button {
                    engine.play(preset.rhythm)
                    lastPayload = preset.rhythm.payload
                } label: {
                    HStack {
                        Text(preset.name)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Spacer()
                        Text("\(preset.rhythm.tapCount) 击 · \(preset.rhythm.totalDuration)ms")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                        Image(systemName: "play.fill")
                            .font(.caption)
                            .foregroundStyle(.pink)
                    }
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var recordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("录制自己的节奏")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Button {
                recorder.tap()
            } label: {
                VStack(spacing: 8) {
                    Image(systemName: recorder.isRecording ? "hand.tap.fill" : "hand.tap")
                        .font(.system(size: 28))
                        .foregroundStyle(.pink)
                    Text(recorder.gaps.isEmpty ? "点我开始，随后按节奏点按" : "继续点按 · \(recorder.gaps.count + 1) 击")
                        .font(.caption.weight(.medium))
                }
                .frame(maxWidth: .infinity, minHeight: 74)
                .background(Color.pink.opacity(0.16), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            HStack(spacing: 10) {
                Button("回放") {
                    if let draft = recorder.draft {
                        engine.play(draft)
                        lastPayload = draft.payload
                    }
                }
                .disabled(recorder.draft == nil)

                Button("清空", role: .destructive) {
                    recorder.reset()
                }
                .disabled(recorder.gaps.isEmpty)
            }
            .buttonStyle(.bordered)
        }
    }

    /// 间隔可视化：条形长度正比于间隔，一眼看出节奏形状
    @ViewBuilder
    private var gapBar: some View {
        let rhythm = recorder.draft
        if let gaps = rhythm?.gaps, !gaps.isEmpty {
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(Array(gaps.enumerated()), id: \.offset) { _, gap in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.pink.opacity(0.7))
                        .frame(width: 14, height: CGFloat(10 + gap * 22 / Rhythm.maxGap))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var payloadSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("payload（发给 iPhone 的 kind 值）")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(lastPayload)
                .font(.system(.caption2, design: .monospaced))
        }
    }
}