//
//  ChatStatusViews.swift
//  ChatBotAiPackage
//
//  Failure state shown inside a chat.
//

import SwiftUI
import EkaUI

/// Shown under a question whose answer failed, with a way to ask again.
struct FailedReplyRow: View {
  let failure: FailedReply
  let onRetry: () -> Void

  var body: some View {
    HStack(alignment: .top, spacing: EkaSpacing.spacingS) {
      Image(systemName: iconName)
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(.orange)
        .frame(width: 28, height: 28)

      VStack(alignment: .leading, spacing: EkaSpacing.spacingXs) {
        VStack(alignment: .leading, spacing: EkaSpacing.spacingXxxs) {
          Text(failure.title)
            .font(.subheadline.weight(.semibold))
          Text(failure.message)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Button(action: onRetry) {
          Label("Retry", systemImage: "arrow.clockwise")
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, EkaSpacing.spacingS)
            .padding(.vertical, EkaSpacing.spacingXs)
        }
        .buttonStyle(.plain)
        .chatGlass(in: Capsule())
      }

      Spacer(minLength: 0)
    }
    .padding(EkaSpacing.spacingS)
    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    .transition(.opacity.combined(with: .move(edge: .bottom)))
    .accessibilityElement(children: .combine)
  }

  private var iconName: String {
    switch failure.error {
    case .offline: "wifi.slash"
    case .authExpired, .authRejected: "lock.trianglebadge.exclamationmark"
    case .timedOut: "clock.badge.exclamationmark"
    case .fileUploadFailed, .filesNotAttached: "paperclip.badge.ellipsis"
    default: "exclamationmark.triangle"
    }
  }
}
