//
//  AudioPlayerManager.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 04/03/25.
//

import AVFoundation
import EkaVoiceToRx
import SwiftData

class AudioPlayerManager {
  
  private var audioPlayer: AVAudioPlayer?
  
  func prepareAudio(
    sessionID: UUID
  ) {
    let m4aFileName = "full_audio.m4a_"
    let completeUrl = DocAssistFileHelper.getDocumentDirectoryURL()
      .appendingPathComponent(sessionID.uuidString).appendingPathComponent(m4aFileName)
    print("#BB Audio URL: \(completeUrl)")
    do {
      audioPlayer = try AVAudioPlayer(contentsOf: completeUrl)
      audioPlayer?.prepareToPlay()
    } catch {
      print("#BB Error initializing audio player: \(error.localizedDescription)")
    }
  }
  
  func playAudio(
    sessionID: UUID
  ) {
    prepareAudio(sessionID: sessionID)
    configureAudioSession()
    audioPlayer?.play()
  }
  
  private func getLastPathComponentFromV2rxDb(sessionID: UUID) async -> String? {
    let descriptor = FetchDescriptor<VoiceConversationModel>(
      predicate: #Predicate { $0.id == sessionID }
    )
    let model = await VoiceConversationAggregator.shared.fetchVoiceConversation(using: descriptor)
    return model.first?.fileURL
  }
  
  private func configureAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("#BB Error configuring audio session: \(error.localizedDescription)")
    }
  }

func stopAudio() {
    audioPlayer?.stop()
  }
}
