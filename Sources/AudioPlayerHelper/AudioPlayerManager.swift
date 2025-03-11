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
    do {
      audioPlayer = try AVAudioPlayer(contentsOf: completeUrl)
      audioPlayer?.prepareToPlay()
    } catch {
      print("Error initializing audio player: \(error.localizedDescription)")
    }
  }
  
  func playAudio(
    sessionID: UUID
  ) {
  //  prepareAudio(sessionID: sessionID)
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
      print("Error configuring audio session: \(error.localizedDescription)")
    }
  }

func stopAudio() {
    audioPlayer?.stop()
  }
  
  func getDuration() -> String? {
    guard let duration = audioPlayer?.duration else { return nil }
    let minutes = Int(duration) / 60
    let seconds = Int(duration) % 60
    return String(format: "%02dm:%02ds", minutes, seconds)
  }
}
