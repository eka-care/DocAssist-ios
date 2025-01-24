//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 24/01/25.
//

import SwiftUI

struct TimerView: View {
  @State var isTimerRunning = false
  @State private var startTime = Date()
  @State private var timerString = "00:00"
  
  let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
  
  var body: some View {
    
    Text(self.timerString)
      .font(
        Font.custom("Lato-Regular", size: 16)
          .weight(.bold)
      )
      .foregroundColor(Color(red: 0.64, green: 0.64, blue: 0.64))
      .onReceive(timer) { _ in
        if self.isTimerRunning {
          let elapsedTime = Date().timeIntervalSince(self.startTime)
          self.timerString = formatTime(elapsedTime)
        }
      }
      .onAppear {
        isTimerRunning = true
      }
      .onDisappear {
        isTimerRunning = false
        if !isTimerRunning {
          startTime = Date()
          timerString = "00:00"
        }
      }
  }
  
  private func formatTime(_ timeInterval: TimeInterval) -> String {
    let minutes = Int(timeInterval) / 60
    let seconds = Int(timeInterval) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
}
