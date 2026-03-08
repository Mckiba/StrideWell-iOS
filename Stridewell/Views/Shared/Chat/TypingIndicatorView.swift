//
//  TypingIndicatorView.swift
//  Stridewell
//

import SwiftUI

struct TypingIndicatorView: View {

    @State private var phase = 0

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .frame(width: 8, height: 8)
                    .foregroundStyle(Color(.tertiaryLabel))
                    .scaleEffect(phase == index ? 1.4 : 1.0)
                    .animation(.spring(duration: 0.3), value: phase)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .task {
            while !Task.isCancelled {
                phase = (phase + 1) % 3
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
        }
    }
}

#Preview {
    TypingIndicatorView()
        .padding()
}
