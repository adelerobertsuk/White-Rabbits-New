//
//  DictationManager.swift
//  WhiteRabbits
//
//  Powers the journal's "Voice to text" button: on-device speech
//  recognition only, nothing recorded or sent anywhere. The mic and the
//  audio session are both switched off the moment listening stops.
//

import Foundation
import Combine
import Speech
import AVFoundation

@MainActor
final class DictationManager: NSObject, ObservableObject {
    @Published private(set) var isListening = false
    @Published private(set) var transcript = ""
    @Published var authorizationDenied = false

    private let recognizer: SFSpeechRecognizer? = SFSpeechRecognizer(locale: Locale.current) ?? SFSpeechRecognizer()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private let engine = AVAudioEngine()

    func toggle() {
        isListening ? stop() : start()
    }

    func start() {
        guard !isListening else { return }
        transcript = ""
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            Task { @MainActor in
                guard let self else { return }
                guard status == .authorized else {
                    self.authorizationDenied = true
                    return
                }
                self.requestMicAndBegin()
            }
        }
    }

    private func requestMicAndBegin() {
        #if os(iOS)
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }
                guard granted else {
                    self.authorizationDenied = true
                    return
                }
                self.beginSession()
            }
        }
        #else
        beginSession()
        #endif
    }

    private func beginSession() {
        guard let recognizer, recognizer.isAvailable else { return }

        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try? session.setActive(true, options: .notifyOthersOnDeactivation)
        #endif

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        self.request = request

        let node = engine.inputNode
        let format = node.outputFormat(forBus: 0)
        node.removeTap(onBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        engine.prepare()
        do {
            try engine.start()
        } catch {
            request.endAudio()
            self.request = nil
            return
        }

        isListening = true
        task = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || result?.isFinal == true {
                    self.stop()
                }
            }
        }
    }

    func stop() {
        guard isListening else { return }
        engine.stop()
        engine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        isListening = false
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        #endif
    }
}
