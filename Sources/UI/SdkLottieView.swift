//
//  SdkLottieView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 23/01/25.
//

import SwiftUI
import Lottie

struct SdkLottieView: UIViewRepresentable {
    let lottieFile: String
    let loopMode: LottieLoopMode
    
    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(name: lottieFile)
        animationView.loopMode = loopMode
        animationView.play()
        return animationView
    }
    
    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}
