//
//  VoiceToRxTip.swift
//  DocAssist-ios
//
//  Created by Brunda  B on 30/05/25.
//

import Foundation
import TipKit

struct VoiceToRxTip: Tip {
    static let voiceToRxVisited = Event(id: "setVoiceToRxVisited")
    
    private var tipMessage = "DocAssist AI can either listen to your live consultation or your dictation to create a medical document"
    private var tipTitle = "Create medical document"
    
    var title: Text {
        Text(tipTitle)
    }
    
    var message: Text? {
        Text(tipMessage)
    }
    
    var image: Image? {
        Image(.voiceToRx)
    }
    
    var rules: [Rule] {
        #Rule(Self.voiceToRxVisited) { event in
            event.donations.count == 0
        }
    }
    
    var options: [TipOption] {
        [
            Tip.MaxDisplayCount(1)
        ]
    }
}
