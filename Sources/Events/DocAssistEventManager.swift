//
//  DocAssistEventManager.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 19/02/25.
//

import Foundation
import Mixpanel

enum DocAssistAnalyticsEvent: String {
  case docAssistLandingPage = "doc_assist_landing_page"
  case docAssistLandingPgClick = "doc_assist_landing_pg_click"
  case docAssistHistoryPage = "doc_assist_history_page"
  case docAssistHistoryClicks = "doc_assist_history_clicks"
  case docAssistHistoryTopNav = "doc_assist_history_top_nav"
}

public class DocAssistEventManager {
  
    public var mixpanel: MixpanelInstance?
    public static let shared = DocAssistEventManager()
    
    private init() { }
    
  func trackEvent(event: DocAssistAnalyticsEvent, properties: Properties?) {
    if let mixpanel {
      mixpanel.track(event: event.rawValue, properties: properties)
    }
  }
}
