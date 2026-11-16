//
//  MessageTextView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 03/03/25.
//
//  How a message's content is drawn: the doctor's message as a tinted bubble,
//  the assistant's answer as plain Markdown on the page.
//

import SwiftUI
import MarkdownUI
import EkaUI

/// The doctor's message: attachments, then a tinted bubble aligned to the trailing edge.
struct UserMessageBubble: View {
  let text: String?
  let imageUrls: [String]?

  var body: some View {
    VStack(alignment: .trailing, spacing: EkaSpacing.spacingXs) {
      if let imageUrls, !imageUrls.isEmpty {
        MessageImages(imageUrls: imageUrls)
      }
      if let text, !text.isEmpty {
        Text(text)
          .font(.body)
          .foregroundStyle(.white)
          .textSelection(.enabled)
          .padding(.horizontal, EkaSpacing.spacingS)
          .padding(.vertical, EkaSpacing.spacingS)
          .background(Color.primaryprimary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
          .contextMenu {
            Button {
              UIPasteboard.general.string = text
            } label: {
              Label("Copy", systemImage: "doc.on.doc")
            }
          }
      }
    }
    .frame(maxWidth: .infinity, alignment: .trailing)
    .padding(.leading, EkaSpacing.spacingXxl)
  }
}

/// The assistant's answer: Markdown straight on the page, like Messages' Apple Intelligence replies.
struct AssistantMessageText: View {
  let text: String

  var body: some View {
    Markdown(text)
      .markdownTheme(.docAssist)
      .textSelection(.enabled)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

/// Attached images as rounded thumbnails.
struct MessageImages: View {
  let imageUrls: [String]

  var body: some View {
    HStack(spacing: EkaSpacing.spacingXs) {
      ForEach(Array(imageUrls.enumerated()), id: \.offset) { _, path in
        AsyncImage(url: DocAssistFileHelper.getDocumentDirectoryURL().appendingPathComponent(path)) { phase in
          switch phase {
          case .success(let image):
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
          default:
            Rectangle()
              .fill(Color(.secondarySystemFill))
              .overlay { ProgressView() }
          }
        }
        .frame(width: 96, height: 96)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      }
    }
  }
}

extension MarkdownUI.Theme {
  /// System typography and semantic colours, so answers follow Dynamic Type and dark mode.
  static let docAssist = Theme.basic
    .text {
      ForegroundColor(Color(.label))
      FontSize(17)
    }
    .code {
      FontFamilyVariant(.monospaced)
      FontSize(.em(0.88))
      BackgroundColor(Color(.secondarySystemFill))
    }
    .link {
      ForegroundColor(Color.primaryprimary)
    }
}

/// Body of the PDF made when an answer is shared.
struct PdfBodyView: View {
  let text: String

  var body: some View {
    VStack {
      Markdown(text)
    }
    .padding(.horizontal, EkaSpacing.spacingM)
    .padding(.top, EkaSpacing.spacingM)
  }
}
