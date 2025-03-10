//
//  V2RxChatView.swift
//  DocAssist-ios
//
//  Created by Arya Vashisht on 05/03/25.
//

import SwiftUI
import EkaVoiceToRx
import AVFoundation

struct VoiceToRxChatView: View {
  
  // MARK: - Properties
  
  @State private var audioPlayer: AVAudioPlayer?
  @State private var isPlaying = false
  @State var v2rxState: DocAssistV2RxState?
  var createdAt: Date
  var audioManger = AudioPlayerManager()
  let viewModel: ChatViewModel
  let v2rxsessionId: UUID
  @ObservedObject var v2rxViewModel: VoiceToRxViewModel
    
  private var statusText: String {
    switch v2rxState {
    case .draft:
      return "Draft"
    case .saved:
      return "Saved"
    case .retry:
      return "Tap to try again"
    default:
      return "Unknown"
    }
  }
  
  private var v2rximage: UIImage {
    switch v2rxState {
    case .draft:
      return UIImage(resource: .draftV2Rx)
    case .saved:
      return UIImage(resource: .savedV2Rx)
    case .retry:
      return UIImage(resource: .smartReportFailure)
    case .none:
      return UIImage(resource: .draftV2Rx)
    }
  }
  
  private var v2rxStateColor: Color {
    switch v2rxState {
    case .draft:
      return .yellow
    case .saved:
      return .green
    case .retry:
      return .red
    case .none:
      return .gray
    }
  }
  
  private var formattedDate: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd MMM’yy"
    return formatter.string(from: createdAt)
  }
  
  // MARK: - Body
  
  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      VStack(alignment: .leading) {
        HStack {
          Image(uiImage: v2rximage)
            .foregroundColor(.green)
            .font(.system(size: 24))
          Text("View clinical notes")
            .font(.headline)
            .foregroundColor(.black)
        }
        HStack {
          Text(formattedDate)
            .font(.subheadline)
            .foregroundColor(.gray)
            .padding(.leading, 20)
          Text(statusText)
            .font(.subheadline)
            .foregroundColor(v2rxStateColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(v2rxStateColor.opacity(0.15))
            .cornerRadius(8)
          Spacer()
        }
      }
      .padding()
      .background(Color.white)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      HStack {
        Button(action: {
          isPlaying.toggle()
          if isPlaying {
            audioManger.playAudio(session: v2rxsessionId)
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
          .font(Font.custom("Lato", size: 14))
        Spacer()
      }
      .padding()
      .background(Color.gray.opacity(0.1))
      .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    .padding()
    .onAppear {
      Task {
        v2rxState = await V2RxDocAssistHelper.fetchV2RxState(for: v2rxsessionId)
      }
    }
    .onTapGesture {
      if v2rxState == .retry {
        // TODO: - Call for retry
      } else {
        viewModel.navigateToDeepThought(id: v2rxsessionId)
      }
    }
  }
}
