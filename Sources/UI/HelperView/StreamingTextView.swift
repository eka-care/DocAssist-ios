//
//  StreamingTextView.swift
//  DocAssist-ios
//

import SwiftUI
import MarkdownUI
import EkaUI

/// Displays bot text with a typewriter animation during live streaming.
/// Only used while `viewModel.streamStarted` is true; discarded after eos.
struct StreamingTextView: View {
  let text: String

  @State private var displayedText: String = ""
  @State private var animationTask: Task<Void, Never>? = nil

  var body: some View {
    Markdown(displayedText.isEmpty ? " " : displayedText)
      .font(.body)
      .padding(8)
      .background(Color.clear)
      .foregroundColor(.neutrals800)
      .customCornerRadius(12, corners: [.bottomLeft, .bottomRight, .topLeft])
      .onAppear {
        animate(to: text)
      }
      .onChange(of: text) { _, newText in
        animate(to: newText)
      }
  }

  private func animate(to fullText: String) {
    guard fullText.count > displayedText.count else {
      displayedText = fullText
      return
    }

    // Cancel any in-flight animation before starting a new one
    animationTask?.cancel()

    let startCount = displayedText.count
    animationTask = Task {
      let startIndex = fullText.index(fullText.startIndex, offsetBy: startCount)
      let newChunk = String(fullText[startIndex...])
      for char in newChunk {
        if Task.isCancelled { return }
        try? await Task.sleep(nanoseconds: 15_000_000) // 15ms per char
        if Task.isCancelled { return }
        await MainActor.run { displayedText.append(char) }
      }
    }
  }
}
