//
//  ChatGlass.swift
//  ChatBotAiPackage
//
//  Liquid Glass for the chat chrome on iOS 26, with a frosted-material
//  look-alike on earlier versions.
//

import SwiftUI

extension View {
  /// Glass behind this view, clipped to `shape`. `tint` colours the glass (for primary actions);
  /// `interactive` makes it react to touch on iOS 26.
  @ViewBuilder
  func chatGlass<S: Shape>(in shape: S, tint: Color? = nil, interactive: Bool = true) -> some View {
    if #available(iOS 26.0, *) {
      glassEffect(glass(tint: tint, interactive: interactive), in: shape)
    } else {
      background {
        if let tint {
          shape.fill(tint)
        } else {
          shape.fill(.regularMaterial)
            .overlay(shape.stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
        }
      }
      .shadow(color: .black.opacity(0.08), radius: 10, y: 3)
    }
  }

  @available(iOS 26.0, *)
  private func glass(tint: Color?, interactive: Bool) -> Glass {
    var glass = Glass.regular
    if let tint {
      glass = glass.tint(tint)
    }
    return interactive ? glass.interactive() : glass
  }
}

/// Groups nearby glass shapes so they blend and morph into each other on iOS 26.
struct ChatGlassContainer<Content: View>: View {
  var spacing: CGFloat = 8
  @ViewBuilder var content: Content

  var body: some View {
    if #available(iOS 26.0, *) {
      GlassEffectContainer(spacing: spacing) { content }
    } else {
      content
    }
  }
}
