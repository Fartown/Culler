import SwiftUI

struct ImportErrorView: View {
    let errors: [ImportErrorItem]
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.yellow)

            Text("操作完成，但有部分失败")
                .font(.title2)
                .fontWeight(.bold)

            Text("失败 \(errors.count) 项")
                .foregroundColor(.secondary)

            List(errors) { error in
                VStack(alignment: .leading) {
                    Text(error.filename)
                        .fontWeight(.medium)
                    Text(error.reason)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            .frame(maxHeight: 200)
            .border(Color.secondary.opacity(0.2))

            Button("Close") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(24)
        .frame(width: 400)
    }
}
