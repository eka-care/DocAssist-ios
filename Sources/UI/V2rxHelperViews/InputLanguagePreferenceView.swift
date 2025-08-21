//
//  InputLanguagePreferenceView.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 19/08/25.
//
import SwiftUI

protocol DisplayNameProviding {
    var displayName: String { get }
}

enum InputLanguage: String, CaseIterable, Identifiable,DisplayNameProviding {
  case english = "en-IN"
  case hindi = "hi"
  case kannada = "kn"
  case tamil = "ta"
  case telugu = "te"
  case bengali = "bn"
  case malayalam = "ml"
  case gujarati = "gu"
  case marathi = "mr"
  case punjabi = "pa"

  var displayName: String {
    switch self {
    case .english: return "English"
    case .hindi: return "Hindi"
    case .kannada: return "Kannada"
    case .tamil: return "Tamil"
    case .telugu: return "Telugu"
    case .bengali: return "Bengali"
    case .malayalam: return "Malayalam"
    case .gujarati: return "Gujarati"
    case .marathi: return "Marathi"
    case .punjabi: return "Punjabi"
    }
  }

  var id: String { rawValue }
}

struct InputLanguagePreferenceView: View {
  private let languages = InputLanguage.allCases

  @AppStorage(PreferenceKeys.selectedLanguages) private var storedLanguages: String = "en-IN,hi"
  @State private var selectedLanguages: Set<InputLanguage> = []
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack {
      MultiSelectList(
        title: "Select up to 2 languages",
        options: languages,
        maxSelection: 2,
        selectedItems: $selectedLanguages,
        footerText: "These settings are not permanent and can be changed later as well when you start a new session"
      )
      Spacer()
      Button(action: {
        storedLanguages = selectedLanguages.map(\.rawValue).joined(separator: ",")
        print("Saved preference: \(storedLanguages)")
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
      if !storedLanguages.isEmpty {
        let keys = Set(
          storedLanguages
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        )
        print("#BB keys are \(keys)")
        selectedLanguages = Set(languages.filter { keys.contains($0.rawValue) })
        print("#BB selected language are \(selectedLanguages)")
      } else {
        print("#BB it's empty")
      }
    }
    .navigationTitle("Languages")
    .navigationBarTitleDisplayMode(.inline)
  }
}
