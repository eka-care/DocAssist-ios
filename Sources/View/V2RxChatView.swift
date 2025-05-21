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
  @State var v2rxState: DocAssistV2RxState = .loading
  var createdAt: Date
  var audioManger = AudioPlayerManager()
  let viewModel: ChatViewModel
  let v2rxSessionId: UUID
  @State var updatedSessionID: String?
  @State var audioDuration: String = ""
  @ObservedObject var v2rxViewModel: VoiceToRxViewModel
  
  private enum Constants {
    static let draft = "Draft"
    static let saved = "Saved"
    static let tapToTryAgain = "Tap to try again"
    static let recordAgain = "Record again"
    static let viewClinicalNotes = "View clinical notes"
    static let failedToAnalyze = "Failed to analyse"
    static let somethingWentWrong = "Something went wrong"
    static let recording = "Recording"
    static let dateFormat = "dd MMM'yy"
  }
    
  private var statusText: String {
    switch v2rxState {
    case .draft:
      return Constants.draft
    case .saved:
      return Constants.saved
    case .retry:
      return Constants.tapToTryAgain
    default:
      return Constants.recordAgain
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
      return UIImage(resource: .smartReportFailure)
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
      return .red
    }
  }
  
  private var v2rxStateTitle: String {
    switch v2rxState {
    case .draft, .saved:
      Constants.viewClinicalNotes
    case .retry:
      Constants.failedToAnalyze
    default:
      Constants.somethingWentWrong
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
      } else {
        VStack(alignment: .leading, spacing: 0) {
          Button {
            if v2rxStateTitle == Constants.somethingWentWrong {
              print("Record again")
            } else {
              if v2rxState == .retry {
                /// Retry file uploads if pending from local
                v2rxViewModel.retryIfNeeded()
              } else {
                if let updatedSessionID {
                  viewModel.navigateToDeepThought(id: updatedSessionID)
                } else {
                  viewModel.navigateToDeepThought(id: v2rxSessionId.uuidString)
                }
              }
            }
          } label: {
            VStack(alignment: .leading) {
              HStack {
                Image(uiImage: v2rximage)
                  .foregroundColor(.green)
                  .font(.system(size: 24))
                Text(v2rxStateTitle)
                  .font(.custom("Lato-Bold", size: 16))
                  .foregroundColor(.neutrals1000)
              }
              HStack {
                Text(formattedDate)
                  .font(.custom("Lato-Regular", size: 13))
                  .foregroundColor(.gray)
                  .padding(.leading, 20)
                if v2rxStateTitle != Constants.somethingWentWrong {
                  Text(statusText)
                    .font(.custom("Lato-Bold", size: 12))
                    .foregroundColor(v2rxStateColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(v2rxStateColor.opacity(0.15))
                    .cornerRadius(8)
                }
                Spacer()
              }
            }
          }
          .padding()
          .background(Color.white)
          .customCornerRadius(12, corners: [.bottomLeft, .bottomRight, .topRight])
          if v2rxStateTitle != Constants.somethingWentWrong {
            VStack(alignment: .center) {
              HStack {
                Button(action: {
                  isPlaying.toggle()
                  if isPlaying {
                    audioManger.playAudio(sessionID: v2rxSessionId)
                  } else {
                    audioManger.stopAudio()
                  }
                }) {
                  Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 14)
                    .contentTransition(.symbolEffect(.replace))
                    .foregroundColor(.blue)
                }
                Text(isPlaying ? "Playing..." : "Audio file")
                  .font(.custom("Lato-Regular", size: 14))
                  .foregroundColor(Color(red: 0.28, green: 0.28, blue: 0.28))
                Spacer()
                Text(audioDuration)
                  .font(.custom("Lato-Regular", size: 14))
                  .foregroundColor(Color(red: 0.46, green: 0.46, blue: 0.46))
                
              }
              .padding()
              .background(Color.gray.opacity(0.1))
              .customCornerRadius(12, corners: [.bottomLeft, .bottomRight])
            }
            .padding(.init(top: 0, leading: 12, bottom: 0, trailing: 12))
          }
        }
        .frame(maxWidth: 250)
      }
    }
    .padding()
    .onAppear {
      Task {
        if let state = await V2RxDocAssistHelper.fetchV2RxState(for: v2rxSessionId) {
          print("State is \(state)")
          v2rxState = state
        }
        let models = await VoiceConversationAggregator.shared.fetchVoiceConversation(using: EkaVoiceToRx.QueryHelper.queryForFetch(with: v2rxSessionId))
        if let sessionId = models.first?.updatedSessionID?.uuidString {
          updatedSessionID = "P-PP-\(sessionId)"
        }
      }
      audioManger.prepareAudio(sessionID: v2rxSessionId)
      audioDuration = audioManger.getDuration() ?? ""
    }
    .onChange(of: v2rxViewModel.screenState) { _ , newValue in
      if newValue == .resultDisplay(success: true) ||
          newValue == .resultDisplay(success: false) {
        Task {
          if let state = await V2RxDocAssistHelper.fetchV2RxState(for: v2rxSessionId) {
            v2rxState = state
          }
        }
        audioManger.prepareAudio(sessionID: v2rxSessionId)
        audioDuration = audioManger.getDuration() ?? ""
      }
    }
  }
}
