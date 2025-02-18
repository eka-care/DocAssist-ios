//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 24/01/25.
//

import SwiftUI

struct AudioWaveformView: View {
  @State private var isAnimating = true
  @State private var waveformAmplitudes: [CGFloat] = Array(repeating: 0.0, count: UIDevice.current.userInterfaceIdiom == .pad ? 90 : 30 )
  
  var body: some View {
      HStack(spacing: 4) {
        ForEach(0..<waveformAmplitudes.count, id: \.self) { index in
          Capsule()
            .fill(Color.primaryprimary)
            .frame(width: 2, height: waveformAmplitudes[index])
        }
      .frame(height: 50)
      .onAppear {
        startWaveformAnimation()
      }
    }
  }
  
  private func startWaveformAnimation() {
    guard isAnimating else { return }
    withAnimation(.easeInOut(duration: 0.5)) {
      waveformAmplitudes = waveformAmplitudes.map { _ in CGFloat.random(in: 1...25) }
    }
    
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      if isAnimating {
        startWaveformAnimation()
      }
    }
  }
}
