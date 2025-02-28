//
//  PictureInPictureView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 25/02/25.
//

import SwiftUI
import EkaVoiceToRx

public struct PictureInPictureView: View {
  
  let voiceToRxViewModel: VoiceToRxViewModel
  
  public init(voiceToRxViewModel: VoiceToRxViewModel) {
    self.voiceToRxViewModel = voiceToRxViewModel
  }
  
  public var body: some View {
    AudioMessageView(titleText: "Amit Bharti", voiceToRxViewModel: voiceToRxViewModel)
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
  // MARK: - Init
  
  init(titleText: String, voiceToRxViewModel: VoiceToRxViewModel) {
    self.name = titleText
    self.voiceToRxViewModel = voiceToRxViewModel
  }
  
  // MARK: - Body
  
//  var body: some View {
//    HStack(spacing: 12) {
//      VStack(alignment: .leading) {
//        Text(name)
//          .font(.system(size: 16, weight: .semibold))
//        
//        Text(formatTime(elapsedTime))
//          .font(.system(size: 14))
//          .foregroundColor(.gray)
//      }
//      
//      Spacer()
//      
//      Button(action: {
//        print("#BB recording is stopped")
//        isRecordingStopped = true
//      }) {
//        Image(systemName: "stop.fill")
//          .font(.system(size: 18))
//          .foregroundStyle(.red)
//      }
//    }
//    .padding()
//    .background(
//      LinearGradient(
//        colors: [
//          Color(red: 233/255, green: 237/255, blue: 254/255, opacity: 1.0),
//          Color(red: 248/255, green: 239/255, blue: 251/255, opacity: 1.0)
//        ],
//        startPoint: .leading,
//        endPoint: .trailing
//      )
//    )
//    .clipShape(RoundedRectangle(cornerRadius: 12))
//    .frame(maxWidth: 300)
//    .alert(isPresented: $isRecordingStopped) {
//        Alert(
//            title: Text("Are you done with the conversation"),
//            message: Text("Are you sure you want to stop recording?"),
//            primaryButton: .default(Text("Yes, I'm done")) {
//                stopTimer()
//                voiceToRxViewModel.stopRecording()
//            },
//            secondaryButton: .cancel(Text("Not yet")) {
//                isRecordingStopped = false
//            }
//        )
//    }
//    .onAppear {
//      startTimer()
//    }
//  }
  
  var body: some View {
    ZStack {
      HStack(spacing: 12) {
        VStack(alignment: .leading) {
          Text(name)
            .font(.system(size: 16, weight: .semibold))
          
          Text(formatTime(elapsedTime))
            .font(.system(size: 14))
            .foregroundColor(.gray)
        }
        
        Spacer()
        
        Button(action: {
          print("#BB recording is stopped")
          // Ensure we're on the main thread when updating state
          DispatchQueue.main.async {
            isRecordingStopped = true
          }
        }) {
          Image(systemName: "stop.fill")
            .font(.system(size: 18))
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
    }
    // Place the alert at the ZStack level
    .alert(isPresented: $isRecordingStopped) {
      Alert(
        title: Text("Are you done with the conversation"),
        message: Text("Are you sure you want to stop recording?"),
        primaryButton: .default(Text("Yes, I'm done")) {
          stopTimer()
          voiceToRxViewModel.stopRecording()
        },
        secondaryButton: .cancel(Text("Not yet")) {
          isRecordingStopped = false
        }
      )
    }
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
