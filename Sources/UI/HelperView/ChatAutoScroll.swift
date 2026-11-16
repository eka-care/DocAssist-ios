//
//  ChatAutoScroll.swift
//  ChatBotAiPackage
//
//  Lets a chat follow a streaming answer only while the doctor is at the bottom.
//  Scrolling up pauses following; returning to the bottom resumes it.
//

import SwiftUI

enum ChatScrollSpace {
  static let name = "chatScroll"
  /// How close to the bottom still counts as "at the bottom", in points.
  static let bottomTolerance: CGFloat = 80
}

/// Invisible marker after the last message. Scroll to its id to reach the bottom.
struct ChatBottomMarker: View {
  let id: String

  var body: some View {
    Color.clear
      .frame(height: 1)
      .id(id)
      .background(
        GeometryReader { geometry in
          Color.clear.preference(
            key: ChatBottomMarkerMaxYKey.self,
            value: geometry.frame(in: .named(ChatScrollSpace.name)).maxY
          )
        }
      )
  }
}

private struct ChatBottomMarkerMaxYKey: PreferenceKey {
  static let defaultValue: CGFloat = 0
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

extension View {
  /// Apply to the chat `ScrollView`. Reports whether the bottom marker is on screen
  /// and whether the doctor is scrolling by hand (not a programmatic scroll).
  func trackChatScroll(isNearBottom: Binding<Bool>, isUserScrolling: Binding<Bool>) -> some View {
    modifier(ChatScrollTracking(isNearBottom: isNearBottom, isUserScrolling: isUserScrolling))
  }
}

private struct ChatScrollTracking: ViewModifier {
  @Binding var isNearBottom: Bool
  @Binding var isUserScrolling: Bool
  @State private var viewportHeight: CGFloat = 0
  @State private var markerMaxY: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .coordinateSpace(name: ChatScrollSpace.name)
      .background(
        GeometryReader { geometry in
          Color.clear
            .onAppear { viewportHeight = geometry.size.height }
            .onChange(of: geometry.size.height) { _, height in
              viewportHeight = height
              update()
            }
        }
      )
      .onPreferenceChange(ChatBottomMarkerMaxYKey.self) { maxY in
        markerMaxY = maxY
        update()
      }
      .modifier(UserScrollDetection(isUserScrolling: $isUserScrolling))
  }

  private func update() {
    let nearBottom = markerMaxY - viewportHeight <= ChatScrollSpace.bottomTolerance
    if nearBottom != isNearBottom {
      isNearBottom = nearBottom
    }
  }
}

/// iOS 18 reports scroll phases (including the fling after a drag);
/// iOS 17 falls back to watching the drag itself.
private struct UserScrollDetection: ViewModifier {
  @Binding var isUserScrolling: Bool

  func body(content: Content) -> some View {
    if #available(iOS 18.0, *) {
      content.onScrollPhaseChange { _, phase in
        isUserScrolling = phase == .interacting || phase == .decelerating
      }
    } else {
      content.simultaneousGesture(
        DragGesture(minimumDistance: 10)
          .onChanged { _ in
            if !isUserScrolling { isUserScrolling = true }
          }
          .onEnded { _ in isUserScrolling = false }
      )
    }
  }
}

/// Shown while following is paused; brings the doctor back to the latest message.
struct JumpToLatestButton: View {
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Image(systemName: "arrow.down")
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(.primary)
        .frame(width: 40, height: 40)
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .chatGlass(in: Circle())
    .accessibilityLabel("Jump to latest message")
  }
}
