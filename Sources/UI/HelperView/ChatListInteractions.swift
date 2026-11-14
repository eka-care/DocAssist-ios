//
//  ChatListInteractions.swift
//  ChatBotAiPackage
//
//  The floating New Chat button shared by the chat lists.
//

import SwiftUI

// MARK: - New Chat button

extension View {
  /// A floating New Chat button at the bottom trailing corner, above the list.
  func newChatButton(action: @escaping () -> Void) -> some View {
    /// Room under the last row so it can scroll clear of the button.
    contentMargins(.bottom, 84, for: .scrollContent)
      .overlay(alignment: .bottomTrailing) {
      NewChatFloatingButton(action: action)
        .padding(.trailing, 20)
        .padding(.bottom, 16)
    }
  }
}

private struct NewChatFloatingButton: View {
  let action: () -> Void
  @State private var tapTick = 0

  var body: some View {
    Button {
      tapTick += 1
      action()
    } label: {
      Label("New Chat", systemImage: "plus")
        .font(.custom("Lato-Bold", size: 16))
        .foregroundStyle(.white)
        .padding(.horizontal, 20)
        .frame(minHeight: 52)
        .contentShape(Capsule())
    }
    .buttonStyle(.plain)
    .chatGlass(in: Capsule(), tint: Color.primaryprimary)
    .shadow(color: Color.primaryprimary.opacity(0.35), radius: 12, y: 6)
    .sensoryFeedback(.impact(weight: .light), trigger: tapTick)
    .accessibilityLabel("New chat")
  }
}
