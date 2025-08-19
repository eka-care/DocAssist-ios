//
//  PreferenceView.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 19/08/25.
//

import SwiftUI
import EkaUI

enum PreferenceKeys {
    static let selectedLanguages = "selectedLanguages"
    static let selectedFormats = "selectedFormats"
    static let selectedRecordingMode = "selectedRecordingMode"
}

struct PreferenceView: View {
  @AppStorage(PreferenceKeys.selectedLanguages) private var storedLanguages: String = ""
  @AppStorage(PreferenceKeys.selectedFormats) private var storedFormats: String = ""
  @AppStorage(PreferenceKeys.selectedRecordingMode) private var storedMode: String = RecordingMode.dictation.rawValue

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
                subTitle: storedLanguages.isEmpty ? "Not selected" : storedLanguages,
                style: .tall,
                isSelected: false
              )
            }

            NavigationLink {
              OutputPreferenceView()
            } label: {
              EkaListView(
                title: "Output format(s)",
                subTitle: storedFormats.isEmpty ? "Not selected" : storedFormats,
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

        Button("Start recording") {
          print("Start recording with: \(storedLanguages), \(storedFormats), \(storedMode)")
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.bottom, 10)
      }
    }
  }
}
