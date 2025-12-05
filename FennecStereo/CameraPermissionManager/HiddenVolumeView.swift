//
//  HiddenVolumeView.swift
//  FennecStereo
//
//  Created by Kushkumar on 14/11/25.
//
import SwiftUI
import MediaPlayer

struct HiddenVolumeView: UIViewRepresentable {
    func makeUIView(context: Context) -> MPVolumeView {
        let view = MPVolumeView(frame: .zero)
        view.isHidden = true  // fully hidden
        view.alpha = 0.01     // avoid layout issues
        return view
    }

    func updateUIView(_ uiView: MPVolumeView, context: Context) {}
}

extension View {
    func hiddenVolumeView() -> some View {
        self.overlay(HiddenVolumeView().frame(width: 0, height: 0))
    }
}

