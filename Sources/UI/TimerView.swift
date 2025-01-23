//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 24/01/25.
//

import SwiftUI

struct TimerView: View {
  @State var isTimerRunning = false
  @State private var startTime =  Date()
  @State private var timerString = "0.0"
  let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
  
  var body: some View {
    
    Text(self.timerString)
      .font(
        Font.custom("Lato-Regular", size: 16)
          .weight(.bold)
      )
      .foregroundColor(Color(red: 0.64, green: 0.64, blue: 0.64))
      .onReceive(timer) { _ in
        if self.isTimerRunning {
          let elapsedTime = floor(Date().timeIntervalSince(self.startTime))
          timerString = String(format: "%.2f", elapsedTime)
        }
      }
      .onAppear {
        isTimerRunning = true
      }
      .onDisappear {
        isTimerRunning = false
        if !isTimerRunning {
          startTime = Date()
          timerString = "0.0"
        }
      }
  }
}
