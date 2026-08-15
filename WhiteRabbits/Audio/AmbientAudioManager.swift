//
//  AmbientAudioManager.swift
//  WhiteRabbits
//
//  A soft, generated lofi hiss with the occasional vinyl "crackle".
//  No audio file needed, it's all made in code.
//
//  This uses the .ambient audio session category, which is the
//  polite one: it never interrupts music or a podcast that's already
//  playing, and it goes quiet if Adele flips the silent switch.
//

import AVFoundation
import Combine
import SwiftUI

@MainActor
final class AmbientAudioManager: ObservableObject {
    @Published private(set) var isPlaying = false

    private let engine = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?

    init() {
        configureSession()
        buildGraph()
    }

    // MARK: - Session

    private func configureSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            // .ambient = plays alongside whatever else is already
            // playing, and respects the silent switch. Exactly the
            // "polite background sound" behaviour the spec asks for.
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("White Rabbits: could not configure the ambient audio session (\(error)).")
        }
        #endif
    }

    // MARK: - The sound itself

    private func buildGraph() {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1) else { return }

        var lastSample: Float = 0
        var samplesUntilNextCrackle = Int.random(in: 4_000...20_000)

        let node = AVAudioSourceNode(format: format) { _, _, frameCount, audioBufferList -> OSStatus in
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)
            guard let raw = buffers[0].mData else { return noErr }
            let output = raw.assumingMemoryBound(to: Float.self)

            for frame in 0..<Int(frameCount) {
                var sample = Float.random(in: -1...1) * 0.02

                samplesUntilNextCrackle -= 1
                if samplesUntilNextCrackle <= 0 {
                    sample += Float.random(in: -1...1) * 0.09
                    samplesUntilNextCrackle = Int.random(in: 4_000...20_000)
                }

                // A gentle one-pole low-pass so the hiss feels soft, not sharp.
                let filtered = lastSample + 0.06 * (sample - lastSample)
                lastSample = filtered
                output[frame] = filtered
            }
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 0.5
        sourceNode = node
    }

    // MARK: - Controls

    func toggle() {
        isPlaying ? stop() : start()
    }

    func start() {
        guard !isPlaying else { return }
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
        do {
            try engine.start()
            isPlaying = true
        } catch {
            print("White Rabbits: could not start the ambient sound (\(error)).")
        }
    }

    func stop() {
        engine.pause()
        isPlaying = false
    }
}
