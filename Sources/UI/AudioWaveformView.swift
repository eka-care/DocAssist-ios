//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 24/01/25.
//

import SwiftUI

struct AudioWaveformView: View {
    @State private var isAnimating = true
    @State private var waveformAmplitudes: [CGFloat] = Array(repeating: 0.0, count: 16)

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .leading) {

                HStack(spacing: 4) {
                    ForEach(0..<waveformAmplitudes.count, id: \.self) { index in
                        Capsule()
                            .fill(Color.blue)
                            .frame(width: 4, height: waveformAmplitudes[index])
                    }
                }
                .padding(.horizontal, 16)
            }
            .frame(height: 60)
            .onAppear {
                startWaveformAnimation()
            }
        }
        .padding()
    }

    private func startWaveformAnimation() {
        guard isAnimating else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            waveformAmplitudes = waveformAmplitudes.map { _ in CGFloat.random(in: 10...50) }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if isAnimating {
                startWaveformAnimation()
            }
        }
    }
}
