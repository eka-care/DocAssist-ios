//
//  OutputPreferenceView.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 19/08/25.
//

import SwiftUI

enum OutputFormat: String, CaseIterable, Identifiable, DisplayNameProviding {
  case ekaEmr = "eka_emr_template"
  case transcript = "transcript_template"
  case clinicalNotes = "clinical_notes_template"
  
  var id: String { rawValue }
  
  var displayName: String {
    switch self {
    case .ekaEmr: return "Eka EMR format"
    case .transcript: return "Transcription"
    case .clinicalNotes: return "Clinical notes"
    }
  }
}

struct OutputPreferenceView: View {

  private let formats = OutputFormat.allCases
  @AppStorage(PreferenceKeys.selectedFormats) private var storedFormats: String = "eka_emr_template,transcript_template"
  @State private var selectedFormats: Set<OutputFormat> = []
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
        storedFormats = selectedFormats.map(\.rawValue).joined(separator: ",")
        print("Saved preference: \(storedFormats)")
        dismiss()
      }) {
        Text("Save preference")
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.primaryprimary)
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
        selectedFormats = Set(formats.filter { keys.contains($0.rawValue) })
        print("#BB selected formats are \(selectedFormats)")
      } else {
        print("#BB: No stored formats found")
      }
    }
    .navigationTitle("Output formats")
    .navigationBarTitleDisplayMode(.inline)
  }
}
