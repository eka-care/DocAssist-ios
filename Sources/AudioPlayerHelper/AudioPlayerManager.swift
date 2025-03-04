//
//  AudioPlayerManager.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 04/03/25.
//

import AVFoundation

class AudioPlayerManager {
  
  private var audioPlayer: AVAudioPlayer?
  
  func prepareAudio() {
    
  }
  
  func playAudio() {
    audioPlayer?.play()
  }
  
  func stopAudio() {
    audioPlayer?.stop()
  }
}
