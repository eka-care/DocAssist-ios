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
  let viewModel: ChatViewModel
  let v2rxSessionId: UUID
  @State var updatedSessionID: String?
  @State var audioDuration: String = ""
  @ObservedObject var v2rxViewModel: VoiceToRxViewModel
  let voiceToRxRepo = VoiceToRxRepo()
  
  private enum Constants {
    static let loading = "Recording in progress..."
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
    case .loading:
      return UIImage(resource: .recording)
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
      return .white
    }
  }
  
  private var v2rxStateTitle: String {
    switch v2rxState {
    case .loading:
      Constants.loading
    case .draft, .saved:
      Constants.viewClinicalNotes
    case .retry:
      Constants.failedToAnalyze
    default:
      Constants.failedToAnalyze
      
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
        }
        .frame(maxWidth: 250)
      }
    .padding()
    .onAppear {
      let state = V2RxDocAssistHelper.fetchV2RxState(for: v2rxSessionId)
      v2rxState = state
      print("State is \(state)")
      let model = voiceToRxRepo.fetchVoiceConversation(fetchRequest: EkaVoiceToRx.QueryHelper.fetchRequest(for: v2rxSessionId))
      if let sessionId = model?.updatedSessionID?.uuidString {
        updatedSessionID = "P-PP-\(sessionId)"
      }
    }
    .onChange(of: v2rxViewModel.screenState) { _ , newValue in
      if newValue == .resultDisplay(success: true) ||
          newValue == .resultDisplay(success: false) {
        let state = V2RxDocAssistHelper.fetchV2RxState(for: v2rxSessionId)
        print("State is \(state)")
        v2rxState = state
      } else if newValue == .startRecording {
        let state = V2RxDocAssistHelper.fetchV2RxState(for: v2rxSessionId)
        print("#BB new fetch state \(state)")
        if state == .deleted {
          v2rxState = state
          viewModel.v2rxEnabled = true
          DatabaseConfig.shared.deleteChatMessageByVoiceToRxSessionId(v2RxAudioSessionId: v2rxSessionId)
        }
      }
    }
  }
    
}
