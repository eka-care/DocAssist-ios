//
//  AudioPlayerManager.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 04/03/25.
//

import AVFoundation

class AudioPlayerManager {
  
  private var audioPlayer: AVAudioPlayer?
  
  func prepareAudio(session: UUID) {
    let audioString = session.uuidString + "/full_audio.m4a_"
    let completeUrl = DocAssistFileHelper.getDocumentDirectoryURL().appendingPathComponent(audioString)
    print("#BB Audio URL: \(completeUrl)")
    do {
      audioPlayer = try AVAudioPlayer(contentsOf: completeUrl)
      audioPlayer?.prepareToPlay()
    } catch {
      print("#BB Error initializing audio player: \(error.localizedDescription)")
    }
  }
  
  func playAudio(session: UUID) {
    prepareAudio(session: session)
    configureAudioSession()
    audioPlayer?.play()
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
