import SwiftUI

struct ImportErrorView: View {
    let errors: [ImportErrorItem]
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(.yellow)

            Text("Import Completed with Errors")
                .font(.title2)
                .fontWeight(.bold)

            Text("\(errors.count) items failed to import.")
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
