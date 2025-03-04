//
//  RecordingView.swift
//  ChatBotAiPackage
//
//  Created by Brunda B on 03/03/25.
//

import SwiftUI
import EkaVoiceToRx

struct RecordingView: View {
    let name: String
    let voiceToRxViewModel: VoiceToRxViewModel
    let stopVoiceRecording: () -> Void
    
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading) {
                Text(name)
                    .font(.system(size: 16, weight: .semibold))

                Text(formatTime(elapsedTime))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }

            Spacer()

            Button {
                stopVoiceRecording()
                stopTimer()
            } label: {
                Image(systemName: "stop.fill")
                    .foregroundStyle(.red)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    Color(red: 233/255, green: 237/255, blue: 254/255, opacity: 1.0),
                    Color(red: 248/255, green: 239/255, blue: 251/255, opacity: 1.0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(width: 250)
        .onAppear {
            startTimer()
        }
    }
    
    func startTimer() {
        timer?.invalidate()
        elapsedTime = 0
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        elapsedTime = 0
    }

    func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
