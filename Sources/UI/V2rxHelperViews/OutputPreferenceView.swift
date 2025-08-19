//
//  OutputPreferenceView.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 19/08/25.
//

import SwiftUI

struct OutputPreferenceView: View {
  struct Format: Identifiable, Hashable, CustomStringConvertible {
    let id = UUID()
    let name: String
    var description: String { name }
  }

  private let formats = [
    Format(name: "Eka EMR format"),
    Format(name: "Transcription"),
    Format(name: "Clinical notes")
  ]

  @AppStorage(PreferenceKeys.selectedFormats) private var storedFormats: String = ""
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
        storedFormats = selectedFormats.map(\.name).joined(separator: ", ")
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
        let names = storedFormats.split(separator: ",").map(String.init)
        selectedFormats = Set(formats.filter { names.contains($0.name) })
      }
    }
    .navigationTitle("Output formats")
    .navigationBarTitleDisplayMode(.inline)
  }
}
