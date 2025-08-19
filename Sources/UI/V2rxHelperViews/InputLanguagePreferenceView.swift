//
//  InputLanguagePreferenceView.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 19/08/25.
//

import SwiftUI

struct InputLanguagePreferenceView: View {
  struct Language: Identifiable, Hashable, CustomStringConvertible {
    let id = UUID()
    let name: String
    var description: String { name }
  }

  private let languages = [
    Language(name: "English"),
    Language(name: "Hindi"),
    Language(name: "Kannada"),
    Language(name: "Tamil"),
    Language(name: "Telugu"),
    Language(name: "Bengali"),
    Language(name: "Malayalam"),
    Language(name: "Gujarati"),
    Language(name: "Marathi"),
    Language(name: "Punjabi")
  ]

  @AppStorage(PreferenceKeys.selectedLanguages) private var storedLanguages: String = ""
  @State private var selectedLanguages: Set<Language> = []
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
        storedLanguages = selectedLanguages.map(\.name).joined(separator: ", ")
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
        let names = storedLanguages.split(separator: ",").map(String.init)
        selectedLanguages = Set(languages.filter { names.contains($0.name) })
      }
    }
    .navigationTitle("Languages")
    .navigationBarTitleDisplayMode(.inline)
  }
}
