import SwiftUI

struct ColorButton: View {
    let color: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Circle()
                .fill(Color(hex: color))
                .frame(width: 40, height: 40)
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 3)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HStack {
        ColorButton(color: "#FF3B30", isSelected: true) {}
        ColorButton(color: "#007AFF", isSelected: false) {}
        ColorButton(color: "#34C759", isSelected: false) {}
    }
    .padding()
}
