//
//  MultiSelectList.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 19/08/25.
//

import SwiftUI

struct MultiSelectList<Item: Hashable & Identifiable>: View {
  let title: String
  let options: [Item]
  let maxSelection: Int
  @Binding var selectedItems: Set<Item>
  let footerText: String?
  
  var body: some View {
    List {
      Section(
        header: Text(title).textCase(nil),
        footer:
          HStack(alignment: .top, spacing: 6) {
            Image(systemName: "info.circle.fill")
              .foregroundColor(Color(.textTertiary))
            Text(footerText ?? "")
              .newTextStyle(ekaFont: .caption1Regular, color: .textTertiary)
              .multilineTextAlignment(.leading)
          }
          .padding(.top, 4)
      ) {
        ForEach(options) { option in
          Button {
            toggleSelection(option)
          } label: {
            HStack {
              Text(optionText(option))
              Spacer()
              if selectedItems.contains(option) {
                Image(systemName: "checkmark")
                  .foregroundColor(.blue)
              }
            }
          }
          .foregroundColor(.primary)
        }
      }
    }
    .listStyle(.insetGrouped)
  }
  
  private func toggleSelection(_ option: Item) {
    if selectedItems.contains(option) {
      selectedItems.remove(option)
    } else if selectedItems.count < maxSelection {
      selectedItems.insert(option)
    }
  }
  
  private func optionText(_ option: Item) -> String {
    if let string = option as? String {
      return string
    } else {
      return "\(option)"
    }
  }
}
