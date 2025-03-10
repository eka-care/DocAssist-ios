//
//  V2RxChatView.swift
//  DocAssist-ios
//
//  Created by Arya Vashisht on 05/03/25.
//

import SwiftUI
import EkaVoiceToRx
import AVFoundation

struct V2RxChatView: View {
  
  // MARK: - Properties
  
  @State private var audioPlayer: AVAudioPlayer?
  @State private var isPlaying = false
  @State var v2rxState: DocAssistV2RxState?
  var createdAt: Date
  var audioManger = AudioPlayerManager()
  let viewModel: ChatViewModel
  let v2rxSessionId: UUID
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
    default:
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
    default:
      return .gray
    }
  }
  
  private var v2rxStateTitle: String {
    switch v2rxState {
    case .draft, .saved:
      "View clinical notes"
    case .retry:
      "Failed to analyse"
    default:
      ""
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
      if v2rxState == .loading {
        ProgressView()
      }
      else {
        VStack(alignment: .leading) {
          HStack {
            Image(uiImage: v2rximage)
              .foregroundColor(.green)
              .font(.system(size: 24))
            Text(v2rxStateTitle)
              .font(.custom("Lato-Bold", size: 16))
              .foregroundColor(.black)
          }
          HStack {
            Text(formattedDate)
              .font(.custom("Lato-Regular", size: 13))
              .foregroundColor(.gray)
              .padding(.leading, 20)
            Text(statusText)
              .font(.custom("Lato-Bold", size: 12))
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
              audioManger.playAudio(session: v2rxSessionId)
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
            .font(.custom("Lato-Regular", size: 14))
          Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
      }
    }
    .padding()
    .onAppear {
      Task {
        v2rxState = await V2RxDocAssistHelper.fetchV2RxState(for: v2rxSessionId)
      }
    }
    .onChange(of: v2rxViewModel.screenState) { _ , newValue in
      if newValue == .resultDisplay(success: true) ||
          newValue == .resultDisplay(success: false) {
        Task {
          v2rxState = await V2RxDocAssistHelper.fetchV2RxState(for: v2rxSessionId)
        }
      }
    }
    .onTapGesture {
      if v2rxState == .retry {
        /// Retry file uploads if pending from local
        v2rxViewModel.retryIfNeeded()
      } else {
        viewModel.navigateToDeepThought(id: v2rxSessionId)
      }
    }
  }
}
