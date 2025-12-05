//
//  SettingsToggle.swift
//  FennecStereo
//
//  Created by Kushkumar on 08/10/25.
//
import SwiftUI

struct SettingsToggle: View {
    var title: String
    @Binding var isOn: Bool
    var tintColor: Color = .yellow
    
    var body: some View {
        VStack(spacing: 20) {
            Text(title)
                .font(.footnote)
                .foregroundColor(.white)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: tintColor))
        }
    }
}
