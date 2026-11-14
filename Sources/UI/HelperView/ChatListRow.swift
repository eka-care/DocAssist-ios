//
//  ChatListRow.swift
//  ChatBotAiPackage
//
//  Rows and date sections for the chat lists, matching EkaScribe's past sessions list.
//

import SwiftUI

/// Icon, title, a detail line and a chevron, laid out like EkaScribe's `SessionRowView`.
struct ChatListRow: View {
  let icon: String
  let title: String
  let details: String
  var isSelected = false
  /// Off when the row is a `NavigationLink`, which draws its own chevron.
  var showsChevron = true

  private var primaryColor: Color { isSelected ? .white : Color(.label) }
  private var secondaryColor: Color { isSelected ? .white.opacity(0.85) : Color(.secondaryLabel) }

  var body: some View {
    HStack(spacing: 16) {
      Image(systemName: icon)
        .resizable()
        .scaledToFit()
        .frame(width: 25, height: 25)
        .foregroundStyle(isSelected ? Color.white : Color.primaryprimary)

      VStack(alignment: .leading, spacing: 4) {
        Text(title)
          .font(.custom("Lato-Regular", size: 16))
          .foregroundStyle(primaryColor)
          .lineLimit(1)
        Text(details)
          .font(.custom("Lato-Medium", size: 12))
          .foregroundStyle(secondaryColor)
          .lineLimit(1)
      }

      Spacer()

      if showsChevron {
        Image(systemName: "chevron.right")
          .font(.caption.weight(.semibold))
          .foregroundStyle(secondaryColor)
      }
    }
    .contentShape(Rectangle())
  }
}

extension ChatSession {
  /// A patient chat shows the patient; a general chat shows a chat glyph.
  var listIcon: String {
    isPatientChat ? "person.crop.circle" : "bubble.left.and.text.bubble.right"
  }

  /// "Ramesh Kumar · 12 Thu, 3:40 PM", or just the time for a general chat.
  var listDetails: String {
    let time = ChatListDate.detail(for: updatedAt)
    guard let patientName, !patientName.isEmpty else { return time }
    return "\(patientName) · \(time)"
  }
}

/// Day sections and timestamps, formatted like EkaScribe's past sessions.
enum ChatListDate {
  struct Section: Identifiable {
    let day: Date
    let sessions: [ChatSession]
    var id: Date { day }

    var title: String {
      let calendar = Calendar.current
      if calendar.isDateInToday(day) { return "Today" }
      if calendar.isDateInYesterday(day) { return "Yesterday" }
      return headerFormatter.string(from: day)
    }
  }

  /// Chats grouped by the day they were last active, newest day first.
  static func sections(for sessions: [ChatSession]) -> [Section] {
    let calendar = Calendar.current
    return Dictionary(grouping: sessions) { calendar.startOfDay(for: $0.updatedAt) }
      .map { Section(day: $0.key, sessions: $0.value.sorted { $0.updatedAt > $1.updatedAt }) }
      .sorted { $0.day > $1.day }
  }

  /// "12 Thu, 3:40 PM", as in EkaScribe.
  static func detail(for date: Date) -> String {
    detailFormatter.string(from: date)
  }

  private static let headerFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE, MMMM d"
    return formatter
  }()

  private static let detailFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US")
    formatter.dateFormat = "d EEE, h:mm a"
    return formatter
  }()
}
