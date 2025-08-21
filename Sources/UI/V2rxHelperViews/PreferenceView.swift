//
//  PreferenceView.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 19/08/25.
//

import SwiftUI
import EkaUI
import EkaVoiceToRx

enum PreferenceKeys {
    static let selectedLanguages = "selectedLanguages"
    static let selectedFormats = "selectedFormats"
    static let selectedRecordingMode = "selectedRecordingMode"
}

struct PreferenceView: View {
  @AppStorage(PreferenceKeys.selectedLanguages) private var storedLanguages: String = "en-IN,hi"
  @AppStorage(PreferenceKeys.selectedFormats) private var storedFormats: String = "eka_emr_template,transcript_template"
  @AppStorage(PreferenceKeys.selectedRecordingMode) private var storedMode: String = RecordingMode.dictation.rawValue
  
  let viewModel: ChatViewModel
  let session: String
  @ObservedObject var voiceToRxViewModel: VoiceToRxViewModel
  let messages: [ChatMessageModel]
  @Binding var startVoicetoRx: Bool
  
  var body: some View {
    VStack(spacing: 0) {
      NavigationStack {
        List {
          Section {
            NavigationLink {
              InputLanguagePreferenceView()
            } label: {
              EkaListView(
                title: "Input language(s)",
                subTitle: storedLanguages
                  .split(separator: ",")
                  .compactMap { InputLanguage(rawValue: String($0))?.displayName }
                  .joined(separator: ", "),
                style: .tall,
                isSelected: false
              )
            }
            
            NavigationLink {
              OutputPreferenceView()
            } label: {
              EkaListView(
                title: "Output format(s)",
                subTitle: storedFormats
                  .split(separator: ",")
                  .compactMap { OutputFormat(rawValue: String($0))?.displayName }
                  .joined(separator: ", "),
                style: .tall,
                isSelected: false
              )
            }
            
            NavigationLink {
              RecordingModePickerView()
            } label: {
              EkaListView(
                title: "Mode of recording",
                subTitle: storedMode,
                style: .tall,
                isSelected: false
              )
            }
          } footer: {
            HStack(alignment: .top, spacing: 6) {
              Image(systemName: "info.circle.fill")
                .foregroundColor(Color(.textTertiary))
              
              Text("These settings are not permanent and can be changed later as well when you start a new session. By continuing, you acknowledge that patient consent was taken for AI-assisted scribing. All notes must still be reviewed and approved by you before saving")
                .newTextStyle(ekaFont: .caption1Regular, color: .textTertiary)
                .multilineTextAlignment(.leading)
            }
            .padding(.top, 4)
          }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("EkaScribe preferences")
        
        Button(action: {
          Task {
            await MainActor.run {
              viewModel.v2rxEnabled = false
            }
            let selectedLanguages = storedLanguages
              .split(separator: ",")
              .map { String($0).trimmingCharacters(in: .whitespaces) }

            let selectedFormats = storedFormats
              .split(separator: ",")
              .map { String($0).trimmingCharacters(in: .whitespaces) }

            await FloatingVoiceToRxViewController.shared.showFloatingButton(
              viewModel: voiceToRxViewModel,
              conversationType: storedMode,
              inputLanguage: selectedLanguages,
              templateId: selectedFormats,
              liveActivityDelegate: viewModel.liveActivityDelegate
            )
            await VoiceToRxTip.voiceToRxVisited.donate()
            guard let v2RxSessionId = voiceToRxViewModel.sessionID else { return }
            let _ = await DatabaseConfig.shared.createMessage(
              sessionId: session,
              messageId: (messages.last?.msgId ?? 0) + 1,
              role: .Bot,
              imageUrls: nil,
              v2RxAudioSessionId: v2RxSessionId
            )
          }
          startVoicetoRx = false
        }) {
          Text("Start recording")
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding(.horizontal)
        .padding(.bottom, 10)
      }
    }
  }
}
