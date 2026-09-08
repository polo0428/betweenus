import SwiftUI

struct TouchActionGrid: View {
    let items: [TouchItem]
    let onSend: (TouchItem) -> Void
    let onAddCustom: (String) -> Void
    let onRemoveCustom: (String) -> Void

    @State private var showAddSheet = false

    private var customItems: [TouchItem] {
        items.filter { if case .custom = $0 { return true } else { return false } }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("发送触感")
                .font(.headline)
                .foregroundStyle(.primary)

            ForEach(TouchCategory.allCases) { category in
                categorySection(category)
            }

            if !customItems.isEmpty {
                customSection
            }

            addButton
        }
    }

    private func categorySection(_ category: TouchCategory) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(category.title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(category.kinds.map { TouchItem.preset($0) }) { item in
                    touchCard(item)
                }
            }
        }
    }

    private var customSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("自定义")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.leading, 4)

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(customItems) { item in
                    touchCard(item)
                }
            }
        }
    }

    private func touchCard(_ item: TouchItem) -> some View {
        Button {
            onSend(item)
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                Image(systemName: item.symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(item.tint)

                Spacer(minLength: 12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(item.subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 126, alignment: .leading)
            .padding(16)
            .background(cardBackground(for: item), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(item.tint.opacity(0.18), lineWidth: 1)
            )
            .overlay(alignment: .topTrailing) {
                if case .custom(let text) = item {
                    Button {
                        onRemoveCustom(text)
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(.secondary)
                    }
                    .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var addButton: some View {
        Button {
            showAddSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text("自定义一个触感（如：在加班）")
                    .font(.subheadline.weight(.medium))
            }
            .foregroundStyle(.teal)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.teal.opacity(0.1), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showAddSheet) {
            AddCustomTouchView(onSave: onAddCustom)
        }
    }

    private func cardBackground(for item: TouchItem) -> some ShapeStyle {
        LinearGradient(
            colors: [
                item.tint.opacity(0.18),
                item.tint.opacity(0.08)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private struct AddCustomTouchView: View {
    let onSave: (String) -> Void

    @State private var text = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("输入触感，如：在加班", text: $text)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .onChange(of: text) { value in
                        text = String(value.prefix(10))
                    }

                Text("保存后你和对方的 Watch 上都会多这个选项")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding(20)
            .navigationTitle("自定义触感")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        onSave(text)
                        dismiss()
                    }
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.height(280)])
    }
}