import SwiftUI

struct ImportErrorView: View {
    let errors: [ImportErrorItem]
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                Text("导入失败明细")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .keyboardShortcut(.cancelAction)
                .accessibilityLabel("关闭")
            }
            .padding()

            Divider()

            VStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.yellow)

                Text("操作完成，但有部分失败")
                    .font(.headline)
                    .foregroundColor(.primary)

                Text("失败 \(errors.count) 项")
                    .foregroundColor(.secondary)

                List(errors) { error in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(error.filename)
                            .fontWeight(.medium)
                        Text(error.reason)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxHeight: 220)

                HStack {
                    Spacer()
                    Button("关闭") {
                        onDismiss()
                    }
                    .buttonStyle(.borderedProminent)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
        }
        .frame(width: 480, height: 520)
    }
}
