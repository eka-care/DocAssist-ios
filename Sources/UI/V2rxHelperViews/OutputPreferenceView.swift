//
//  OutputPreferenceView.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 19/08/25.
//

import SwiftUI

struct OutputPreferenceView: View {
  struct Format: Identifiable, Hashable, CustomStringConvertible {
      var id: String { key } 
      let name: String
      let key: String

      var description: String { name }
  }

  private let formats = [
    Format(name: "Eka EMR format", key: "eka_emr_template"),
    Format(name: "Transcription", key: "transcript_template"),
    Format(name: "Clinical notes", key: "clinical_notes_template")
  ]

  @AppStorage(PreferenceKeys.selectedFormats) private var storedFormats: String = "eka_emr_format, transcription"
  @State private var selectedFormats: Set<Format> = []
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    VStack {
      MultiSelectList(
        title: "Select up to 2 formats",
        options: formats,
        maxSelection: 2,
        selectedItems: $selectedFormats,
        footerText: "These settings are not permanent and can be changed later as well when you start a new session"
      )
      Button(action: {
        storedFormats = selectedFormats.map(\.key).joined(separator: ", ")
        print("Saved preference: \(storedFormats)")
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
      if !storedFormats.isEmpty {
        let keys = Set(
          storedFormats
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        )
        print("#BB keys are \(keys)")
        selectedFormats = Set(formats.filter { keys.contains($0.key) })
        print("#BB selected formats are \(selectedFormats)")
      } else {
        print("#BB: No stored formats found")
      }
    }
    .navigationTitle("Output formats")
    .navigationBarTitleDisplayMode(.inline)
  }
}
