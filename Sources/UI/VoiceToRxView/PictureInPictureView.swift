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
    VStack {
      // MARK: - Recording View
      RecordingView(name: "Amit", voiceToRxViewModel: voiceToRxViewModel, stopVoiceRecording: stopVoiceRecording)
      
      // MARK: - Processing View
  //    ProcessingView()
      
      // MARK: - Smart Notes View
  //    SmartNotesView(success: true)
      
    }
  }
}
