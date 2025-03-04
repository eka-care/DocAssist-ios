//
//  SwiftUIView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 03/03/25.
//

import SwiftUI
import EkaVoiceToRx
import AVFoundation

struct ClinicalNotesView: View {
  
  @State private var audioPlayer: AVAudioPlayer?
  @State private var isPlaying = false
  var audioManger = AudioPlayerManager()
  let viewModel: ChatViewModel
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading) {
        HStack {
          Image(systemName: "waveform.circle.fill")
            .foregroundColor(.green)
            .font(.system(size: 24))
          
          Text("View clinical notes")
            .font(.headline)
            .foregroundColor(.black)
        }
        HStack {
          Text("08 Jan’24")
            .font(.subheadline)
            .foregroundColor(.gray)
            .padding(.leading, 40)
          Spacer()
          
          Text("Saved")
            .font(.subheadline)
            .foregroundColor(.green)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.green.opacity(0.15))
            .cornerRadius(8)
        }
      }
      .padding()
      .background(Color.white)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      
      HStack {
        Button(action: {
          
          isPlaying.toggle()
          
          if isPlaying {
            audioManger.playAudio()
            print("#BB playing")
          } else {
            audioManger.stopAudio()
            print("#BB STOPPED")
          }
        }) {
          Image(systemName: isPlaying ? "stop.fill" : "play.fill")
            .foregroundColor(.blue)
            .font(.system(size: 20))
        }
        
        Text("Recording")
          .foregroundColor(.gray)
          .font(.subheadline)
        
        Spacer()
        
        Text("01m 04s")
          .foregroundColor(.gray)
          .font(.subheadline)
        
      }
      .padding()
      .background(Color.gray.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
    .onAppear {
      // TODO: - Fetch clinical notes
      
    }
    .onTapGesture {
      print("#BB deepthought page")
      viewModel.navigateToDeepThought(id: UUID())
    }
  }
}


