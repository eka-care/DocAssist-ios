//
//  PictureInPictureView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 25/02/25.
//

import SwiftUI
import EkaVoiceToRx

struct PictureInPictureView: View {
  
  let voiceToRxViewModel: VoiceToRxViewModel
  let stopVoiceRecording:() -> Void
  
  init(
    voiceToRxViewModel: VoiceToRxViewModel,
    stopVoiceRecording: @escaping () -> Void
  ) {
    self.voiceToRxViewModel = voiceToRxViewModel
    self.stopVoiceRecording = stopVoiceRecording
  }
  
  var body: some View {
    AudioMessageView(name: "Amit Bharti", voiceToRxViewModel: voiceToRxViewModel, stopVoiceRecording: stopVoiceRecording)
      .frame(width: 200, height: 90)
  }
}

struct AudioMessageView: View {
  // MARK: - Properties
  
  @State private var timer: Timer?
  @State private var elapsedTime: TimeInterval = 0
  let name: String
  let voiceToRxViewModel: VoiceToRxViewModel
  @State var isRecordingStopped: Bool = false
  let stopVoiceRecording: () -> Void
  // MARK: - Init

  init(name: String, voiceToRxViewModel: VoiceToRxViewModel, stopVoiceRecording: @escaping () -> Void) {
    self.name = name
    self.voiceToRxViewModel = voiceToRxViewModel
    self.stopVoiceRecording = stopVoiceRecording
  }
  
  // MARK: - Body
  
  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading) {
        Text(name)
          .font(.system(size: 16, weight: .semibold))
        
        Text(formatTime(elapsedTime))
          .font(.system(size: 14))
          .foregroundColor(.gray)
      }
      
      Spacer()
      
      Button {
        stopVoiceRecording()
        isRecordingStopped = true
        stopTimer()
      } label: {
        Image(systemName: "stop.fill")
          .foregroundStyle(.red)
      }
    }
    .padding()
    .background(
      LinearGradient(
        colors: [
          Color(red: 233/255, green: 237/255, blue: 254/255, opacity: 1.0),
          Color(red: 248/255, green: 239/255, blue: 251/255, opacity: 1.0)
        ],
        startPoint: .leading,
        endPoint: .trailing
      )
    )
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .frame(maxWidth: 300)
    .onAppear {
      startTimer()
    }
  }
  
  func startTimer() {
    timer?.invalidate()
    elapsedTime = 0
    timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
      elapsedTime += 1
    }
  }
  
  func stopTimer() {
    timer?.invalidate()
    timer = nil
    elapsedTime = 0
  }
  
  func formatTime(_ time: TimeInterval) -> String {
    let minutes = Int(time) / 60
    let seconds = Int(time) % 60
    return String(format: "%02d:%02d", minutes, seconds)
  }
}

enum Constants {
  static let padding: CGFloat = 20
}
