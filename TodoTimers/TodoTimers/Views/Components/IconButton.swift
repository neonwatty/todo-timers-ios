import SwiftUI

struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title2)
                .frame(width: 50, height: 50)
                .background(isSelected ? Color.blue.opacity(0.2) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("icon-\(icon)")
    }
}

#Preview {
    HStack {
        IconButton(icon: "timer", isSelected: true) {}
        IconButton(icon: "figure.run", isSelected: false) {}
        IconButton(icon: "book.fill", isSelected: false) {}
    }
    .padding()
}
