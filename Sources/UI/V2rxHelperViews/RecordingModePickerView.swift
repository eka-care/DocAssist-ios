//
//  RecordingModePickerView.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 19/08/25.
//

import SwiftUI

enum RecordingMode: String, CaseIterable, Identifiable {
  case conversation = "consultation"
  case dictation = "dictation"
  var id: String { rawValue }
  
  var displayName: String {
    switch self {
    case .conversation : return "Conversation"
    case .dictation : return "Dictation"
    }
  }
}

struct RecordingModePickerView: View {
  @AppStorage(PreferenceKeys.selectedRecordingMode) private var storedMode: String = RecordingMode.dictation.rawValue
  @State private var tempSelectedMode: RecordingMode = .dictation
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack {
      Form {
        Section(
          header: Text("Select a mode of recording").textCase(nil),
          footer: HStack(alignment: .top, spacing: 6) {
            Image(systemName: "info.circle.fill")
              .foregroundColor(Color(.textTertiary))
            Text("These settings are not permanent and can be changed later as well when you start a new session")
              .newTextStyle(ekaFont: .caption1Regular, color: .textTertiary)
              .multilineTextAlignment(.leading)
          }
          .padding(.top, 4)
        ) {
          Picker(
            selection: $tempSelectedMode,
            label: EmptyView()
          ) {
            ForEach(RecordingMode.allCases) { mode in
              Text(mode.displayName).tag(mode)
            }
          }
          .pickerStyle(.inline)
        }
      }

      Spacer()

      Button(action: {
        storedMode = tempSelectedMode.rawValue
        print("Saved preference: \(storedMode)")
        dismiss()
      }) {
        Text("Save preference")
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
      .padding(.horizontal)
      .padding(.bottom, 10)
    }
    .onAppear {
      tempSelectedMode = RecordingMode(rawValue: storedMode) ?? .dictation
    }
    .navigationTitle("Select mode of recording")
    .navigationBarTitleDisplayMode(.inline)
  }
}
