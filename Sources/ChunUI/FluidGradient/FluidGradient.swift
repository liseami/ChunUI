//
//  FluidGradient.swift
//  FluidGradient
//
//  Created by Oskar Groth on 2021-12-23.
//

import SwiftUI

 

public struct FluidGradient: View {
    private var blobs: [Color]
    private var highlights: [Color]
    private var speed: CGFloat
    private var blur: CGFloat
    private var noiseOpacity: CGFloat
    private var noiseScale: CGFloat
    private var noiseSpeed: CGFloat
    
    @State var blurValue: CGFloat = 0.0
    
    public init(blobs: [Color],
                highlights: [Color] = [],
                speed: CGFloat = 1.0,
                blur: CGFloat = 0.75,
                noiseOpacity: CGFloat = 0.1,
                noiseScale: CGFloat = 50.0,
                noiseSpeed: CGFloat = 1.0) {
        self.blobs = blobs
        self.highlights = highlights
        self.speed = speed
        self.blur = blur
        self.noiseOpacity = noiseOpacity
        self.noiseScale = noiseScale
        self.noiseSpeed = noiseSpeed
    }
    
    public var body: some View {
        Representable(blobs: blobs,
                      highlights: highlights,
                      speed: speed,
                      noiseOpacity: noiseOpacity,
                      noiseScale: noiseScale,
                      noiseSpeed: noiseSpeed,
                      blurValue: $blurValue)
        .blur(radius: pow(blurValue, blur))
        .accessibility(hidden: true)
        .clipped()
    }
}

#if os(OSX)
typealias SystemRepresentable = NSViewRepresentable
#else
typealias SystemRepresentable = UIViewRepresentable
#endif

// MARK: - Representable
extension FluidGradient {
    struct Representable: SystemRepresentable {
        var blobs: [Color]
        var highlights: [Color]
        var speed: CGFloat
        var noiseOpacity: CGFloat
        var noiseScale: CGFloat
        var noiseSpeed: CGFloat
        
        @Binding var blurValue: CGFloat
        
        func makeView(context: Context) -> FluidGradientView {
            context.coordinator.view
        }
        
        func updateView(_ view: FluidGradientView, context: Context) {
            context.coordinator.create(blobs: blobs, highlights: highlights)
            context.coordinator.updateNoiseSettings(
                opacity: noiseOpacity,
                scale: noiseScale,
                speed: noiseSpeed
            )
            DispatchQueue.main.async {
                context.coordinator.update(speed: speed)
            }
        }
        
#if os(OSX)
        func makeNSView(context: Context) -> FluidGradientView {
            makeView(context: context)
        }
        func updateNSView(_ view: FluidGradientView, context: Context) {
            updateView(view, context: context)
        }
#else
        func makeUIView(context: Context) -> FluidGradientView {
            makeView(context: context)
        }
        func updateUIView(_ view: FluidGradientView, context: Context) {
            updateView(view, context: context)
        }
#endif
        
        func makeCoordinator() -> Coordinator {
            Coordinator(blobs: blobs,
                        highlights: highlights,
                        speed: speed,
                        noiseOpacity: noiseOpacity,
                        noiseScale: noiseScale,
                        noiseSpeed: noiseSpeed,
                        blurValue: $blurValue)
        }
    }
    
    class Coordinator: FluidGradientDelegate {
        var blobs: [Color]
        var highlights: [Color]
        var speed: CGFloat
        var noiseOpacity: CGFloat
        var noiseScale: CGFloat
        var noiseSpeed: CGFloat
        var blurValue: Binding<CGFloat>
        
        var view: FluidGradientView
        
        public init(blobs: [Color],
             highlights: [Color],
             speed: CGFloat,
             noiseOpacity: CGFloat,
             noiseScale: CGFloat,
             noiseSpeed: CGFloat,
             blurValue: Binding<CGFloat>) {
            self.blobs = blobs
            self.highlights = highlights
            self.speed = speed
            self.noiseOpacity = noiseOpacity
            self.noiseScale = noiseScale
            self.noiseSpeed = noiseSpeed
            self.blurValue = blurValue
            self.view = FluidGradientView(
                blobs: blobs,
                highlights: highlights,
                speed: speed,
                noiseOpacity: noiseOpacity,
                noiseScale: noiseScale,
                noiseSpeed: noiseSpeed
            )
            self.view.delegate = self
        }
        
        /// Create blobs and highlights
        func create(blobs: [Color], highlights: [Color]) {
            guard blobs != self.blobs || highlights != self.highlights else { return }
            self.blobs = blobs
            self.highlights = highlights
            
            view.create(blobs, layer: view.baseLayer)
            view.create(highlights, layer: view.highlightLayer)
            view.update(speed: speed)
        }
        
        /// Update speed
        func update(speed: CGFloat) {
            guard speed != self.speed else { return }
            self.speed = speed
            view.update(speed: speed)
        }
        
        /// Update noise settings
        func updateNoiseSettings(opacity: CGFloat, scale: CGFloat, speed: CGFloat) {
            guard opacity != self.noiseOpacity || 
                  scale != self.noiseScale || 
                  speed != self.noiseSpeed else { return }
            
            self.noiseOpacity = opacity
            self.noiseScale = scale
            self.noiseSpeed = speed
            
            view.updateNoiseSettings(
                opacity: opacity,
                scale: scale,
                speed: speed
            )
        }
        
        func updateBlur(_ value: CGFloat) {
            blurValue.wrappedValue = value
        }
    }
}
