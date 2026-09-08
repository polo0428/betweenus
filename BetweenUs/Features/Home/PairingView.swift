import SwiftUI

struct PairingView: View {
    @ObservedObject var model: PairingModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    statusHeader

                    if model.isPaired {
                        pairedCard
                    } else {
                        generateSection
                        divider
                        bindSection
                    }

                    if let error = model.errorMessage {
                        Text(error)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
                .padding(20)
            }
            .background(pageBackground.ignoresSafeArea())
            .navigationTitle("配对伴侣")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var statusHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(model.isPaired ? "已配对" : "未配对")
                .font(.title2.weight(.semibold))
            Text(model.isPaired
                 ? "现在发出的触感会送达对方手机"
                 : "生成配对码发给对方，或输入对方发来的配对码")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var generateSection: some View {
        VStack(spacing: 14) {
            if let code = model.generatedCode {
                Text(code)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(.pink)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Button {
                Task { await model.generateCode() }
            } label: {
                Text(model.generatedCode == nil ? "生成我的配对码" : "重新生成")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isBusy)
        }
    }

    private var bindSection: some View {
        VStack(spacing: 14) {
            TextField("输入对方的 6 位配对码", text: $model.inputCode)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .font(.title3.weight(.semibold))
                .padding(.vertical, 14)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .onChange(of: model.inputCode) { value in
                    model.inputCode = String(value.prefix(6))
                }

            Button {
                Task { await model.bind() }
            } label: {
                Text("绑定")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(model.isBusy || model.inputCode.count != 6)
        }
    }

    private var pairedCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 40))
                .foregroundStyle(.green)
            Text("配对成功")
                .font(.headline)
            Button("解除配对", role: .destructive) {
                model.unpair()
            }
            .font(.footnote)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var divider: some View {
        HStack {
            Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
            Text("或")
                .font(.caption)
                .foregroundStyle(.secondary)
            Rectangle().fill(Color.secondary.opacity(0.3)).frame(height: 1)
        }
        .padding(.horizontal, 4)
    }

    private var pageBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.07, green: 0.08, blue: 0.10),
                Color(red: 0.11, green: 0.12, blue: 0.15)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}