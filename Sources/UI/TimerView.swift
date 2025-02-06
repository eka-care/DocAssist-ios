//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 24/01/25.
//

import SwiftUI

struct TimerView: View {
  var isTimerRunning: Bool
  @State private var startTime = Date()
  @State private var timerString = "00:00"
  
  let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
  
  var body: some View {
    Text(self.timerString)
      .font(Font.custom("Lato-Regular", size: 16).weight(.bold))
      .foregroundColor(Color(red: 0.64, green: 0.64, blue: 0.64))
      .onReceive(timer) { _ in
        if isTimerRunning {
          let elapsedTime = Date().timeIntervalSince(startTime)
          self.timerString = formatTime(elapsedTime)
        }
      }
      .onAppear {
        if isTimerRunning {
          startTime = Date()
        }
      }
      .onDisappear {
        resetTimer()
      }
  }
  
  private func resetTimer() {
    startTime = Date()
    timerString = "00:00"
  }
  
  private func formatTime(_ timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
}
