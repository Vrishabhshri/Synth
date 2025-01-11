//
//  Synth.swift
//  Synth
//
//  Created by Vrishabh  on 1/10/25.
//

import SwiftUI
import AudioKit
import Tonic
import SoundpipeAudioKit
import Controls
import Keyboard

struct MorphingOscillatorData {
    var frequency: AUValue = 440
    var octaveFrequency: AUValue = 440
    var amplitude: AUValue = 0.2
    var rampDuration: AUValue = 0.1
}

class SynthClass: ObservableObject {
    let engine = AudioEngine()
    @Published var octave = 1
    @Published var noteRange = 2
    let filter : MoogLadder
    @Published var env : AmplitudeEnvelope
    @Published var cutoff = AUValue(20_000) {
        didSet{
            filter.cutoffFrequency = AUValue(cutoff)
        }
    }
    var osc = [MorphingOscillator(index:1,detuningOffset: -0.5),
               MorphingOscillator(index:1,detuningOffset: 0.5),
               MorphingOscillator(index:1)]
    @Published var oscIndices: [AUValue]
    init() {
        filter = MoogLadder(Mixer(osc[0], osc[1], osc[2]), cutoffFrequency: 20_000)
        env = AmplitudeEnvelope(filter, attackDuration: 0.0, decayDuration: 1.0, sustainLevel: 0.0, releaseDuration: 0.25)
        
        oscIndices = osc.map { $0.index }
        engine.output = env
        try? engine.start()
        
    }
    @Published var data = MorphingOscillatorData() {
        didSet {
            
            for i in 0...2 {
                osc[i].start()
                osc[i].$amplitude.ramp(to:
                                        data.amplitude, duration: 0)
            }
            osc[0].$frequency.ramp(to: data.frequency, duration: data.rampDuration)
            osc[1].$frequency.ramp(to: data.frequency, duration: data.rampDuration)
            osc[2].$frequency.ramp(to: data.octaveFrequency, duration: data.rampDuration)
                
        }
    }
    func noteOn(pitch: Pitch, point: CGPoint) {
        
        data.frequency = AUValue(pitch.midiNoteNumber).midiNoteToFrequency()
        data.octaveFrequency = AUValue(pitch.midiNoteNumber-12).midiNoteToFrequency()
        env.openGate()
    
    }
    func noteOff(pitch: Pitch) {
        
        env.closeGate()
        
    }
    func updateOscillatorIndices() {
        for i in 0..<osc.count {
            osc[i].index = oscIndices[i]
        }
    }
}

struct SynthView: View {
    @StateObject var conductor = SynthClass()
    var body: some View {
        ZStack {
            RadialGradient(gradient: Gradient(colors: [.blue.opacity(1), .black]), center: .center, startRadius: 2, endRadius: 650)
            VStack{
                HStack{
                    VStack {
                        Text("Osc 1 Index").padding(.top, 10).font(.system(size: 12)).foregroundStyle(Color.white)
                        Text(String(format: "%.2f", conductor.oscIndices[0])).font(.system(size: 12)).foregroundStyle(Color.white)
                        SmallKnob(value: $conductor.oscIndices[0], range: 0.0 ... 3.0).frame(maxWidth:50).padding(.bottom, 10).onChange(of: conductor.oscIndices[0]) { newValue in
                            conductor.updateOscillatorIndices()
                        }
                    }
                    VStack {
                        Text("Osc 2 Index").padding(.top, 10).font(.system(size: 12)).foregroundStyle(Color.white)
                        Text(String(format: "%.2f", conductor.oscIndices[1])).font(.system(size: 12)).foregroundStyle(Color.white)
                        SmallKnob(value: $conductor.oscIndices[1], range: 0.0 ... 3.0).frame(maxWidth:50).padding(.bottom, 10).onChange(of: conductor.oscIndices[1]) { newValue in
                            conductor.updateOscillatorIndices()
                        }
                    }
                    VStack {
                        Text("Osc 3 Index (Bass)").padding(.top, 10).font(.system(size: 12)).foregroundStyle(Color.white)
                        Text(String(format: "%.2f", conductor.oscIndices[2])).font(.system(size: 12)).foregroundStyle(Color.white)
                        SmallKnob(value: $conductor.oscIndices[2], range: 0.0 ... 3.0).frame(maxWidth:50).padding(.bottom, 10).onChange(of: conductor.oscIndices[2]) { newValue in
                            conductor.updateOscillatorIndices()
                        }
                    }
                }
                HStack{
                    VStack {
                        Text("Filter").padding(.top, 10).font(.system(size: 12)).foregroundStyle(Color.white)
                        Text(String(format: "%.2f", conductor.cutoff)).font(.system(size: 12)).foregroundStyle(Color.white)
                        SmallKnob(value: $conductor.cutoff, range: 12.0 ... 20_000.0).frame(maxWidth:50).padding(.bottom, 10)
                    }
                    VStack {
                        Text("Attack").padding(.top, 10).font(.system(size: 12)).foregroundStyle(Color.white)
                        Text(String(format: "%.2f", conductor.env.attackDuration)).font(.system(size: 12)).foregroundStyle(Color.white)
                        SmallKnob(value: $conductor.env.attackDuration, range: 0.0 ... 30.0).frame(maxWidth:50).padding(.bottom, 10)
                    }
                    VStack {
                        Text("Decay").padding(.top, 10).font(.system(size: 12)).foregroundStyle(Color.white)
                        Text(String(format: "%.2f", conductor.env.decayDuration)).font(.system(size: 12)).foregroundStyle(Color.white)
                        SmallKnob(value: $conductor.env.decayDuration, range: 1.0 ... 30.0).frame(maxWidth:50).padding(.bottom, 10)
                    }
                    VStack {
                        Text("Sustain").padding(.top, 10).font(.system(size: 12)).foregroundStyle(Color.white)
                        Text(String(format: "%.2f", conductor.env.sustainLevel)).font(.system(size: 12)).foregroundStyle(Color.white)
                        SmallKnob(value: $conductor.env.sustainLevel, range: 0.0 ... 30.0).frame(maxWidth:50).padding(.bottom, 10)
                    }
                    VStack {
                        Text("Release").padding(.top, 10).font(.system(size: 12)).foregroundStyle(Color.white)
                        Text(String(format: "%.2f", conductor.env.releaseDuration)).font(.system(size: 12)).foregroundStyle(Color.white)
                        SmallKnob(value: $conductor.env.releaseDuration, range: 0.25 ... 30.0).frame(maxWidth:50).padding(.bottom, 10)
                    }
                }.padding(.top, -25)
                HStack {
                    
                    Button(action: { conductor.noteRange = max(1, conductor.noteRange - 1) }) {
                        Image(systemName:
                        "arrowtriangle.backward.fill")
                        .foregroundColor(.white)
                    }
                    Text("Range: \(conductor.noteRange)").frame(maxWidth: 150).foregroundStyle(Color.white)
                    Button(action: { conductor.noteRange = min(4, conductor.noteRange + 1)}) {
                        Image(systemName:
                        "arrowtriangle.forward.fill")
                        .foregroundColor(.white)
                    }
                    Button(action: { conductor.octave = max(-2, conductor.octave - 1)}) {
                        Image(systemName: "arrowtriangle.backward.fill").foregroundColor(.white)
                    }
                    Text("Octave: \(conductor.octave)").frame(maxWidth: 150).foregroundStyle(Color.white)
                    Button(action: { conductor.octave = min(3, conductor.octave + 1)}) {
                        Image(systemName: "arrowtriangle.forward.fill").foregroundColor(.white)
                    }
                    
                }.frame(maxWidth:400)
    
                SwiftUIKeyboard(firstOctave: conductor.octave, octaveCount: conductor.noteRange, noteOn: conductor.noteOn(pitch:point:), noteOff: conductor.noteOff)
                    .frame(maxHeight: 600)
            }
            
        }
    }
}

struct SynthView_Previews: PreviewProvider {static var
    previews: some View {SynthView().previewInterfaceOrientation(.landscapeRight)}}
