//
//  SettingsView.swift
//  FennecStereo
//
//  Created by Hiren Nakum on 01/10/25.
//

import SwiftUI

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
  //  @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject var viewModel: HomeViewModel
                     
    private var toggles: [SettingToggleItem] {
        [
            .init(title: "Separate Photos", binding: $viewModel.separatePhotos, tintColor: .yellow),
            .init(title: "Shutter Sound", binding: $viewModel.shutterSound, tintColor: .yellow),
            .init(title: "Level", binding: $viewModel.level, tintColor: .yellow),
            .init(title: "Border", binding: $viewModel.border, tintColor: .yellow),
            .init(title: "Fuse dot guide", binding: $viewModel.fuseDotGuide, tintColor: .yellow),
            .init(title: "Grid", binding: $viewModel.grid, tintColor: .yellow)
        ]
    }
    
    var body: some View {
        VStack(spacing: 20) {
            header
            settingsList
            footer
        }
        .background(Border.color(border: .backGround).ignoresSafeArea())
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onChange(of: viewModel.separatePhotos) { oldValue, newValue in
            UserDefaults.standard.separatePhotos = newValue
        }
        .onChange(of: viewModel.shutterSound) { oldValue, newValue in
            UserDefaults.standard.shutterSound = newValue
        }
        .onChange(of: viewModel.level) { oldValue, newValue in
            UserDefaults.standard.level = newValue
        }
        .onChange(of: viewModel.border) { oldValue, newValue in
            UserDefaults.standard.border = newValue
        }
        .onChange(of: viewModel.fuseDotGuide) { oldValue, newValue in
            UserDefaults.standard.fuseDotGuide = newValue
        }
        .onChange(of: viewModel.grid) { oldValue, newValue in
            UserDefaults.standard.grid = newValue
        }
        .onChange(of: viewModel.selectedBorderColor) { oldValue, newValue in
            UserDefaults.standard.borderName = newValue
        }
    }
}

// MARK: - Subviews
private extension SettingsView {
    
    var header: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.white)
            }
            Spacer()
            Text("Settings")
                .foregroundColor(.white)
                .font(.headline)
            Spacer()
            Spacer().frame(width: 24)
        }
        .padding(.horizontal)
        .padding(.top, 12)
    }
    
    var settingsList: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                ForEach(self.toggles) { toggleItem in
                    VStack(spacing: 20) {
                        SettingsToggle(
                            title: toggleItem.title,
                            isOn: toggleItem.binding,
                            tintColor: toggleItem.tintColor
                        )
                        
                        // If "Border" → show color options
                        if toggleItem.title == "Border" && toggleItem.binding.wrappedValue {
                            HStack(spacing: 8) {
                                ForEach(viewModel.borderOptions, id: \.self) { option in
                                    BorderOption(
                                        title: option,
                                        selected: $viewModel.selectedBorderColor
                                    )
                                }
                            }
                        }
                        
                        Divider()
                            .frame(width: 100, height: 2)
                            .background(Color.gray)
                    }
                }
            }
            .frame(width: AppUtils.screenWidth)
        }
    }
    
    var footer: some View {
        VStack(spacing: 16) {
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                    Text("Love It")
                }
                .foregroundColor(.white)
                .font(.footnote)
                .padding(.vertical, 8)
                .padding(.horizontal, 8)
                .background(Color.gray.opacity(0.6))
                .cornerRadius(10)
            }
            .padding(.top, 10)
            
            HStack(spacing: 20) {
                Image("instagram")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .onTapGesture { viewModel.openInstagram() }
                
                Image("youtube")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .onTapGesture { viewModel.openYouTube() }
            }
            .padding(.top, 20)
            
            VStack(spacing: 16) {
                Text("See more 3D photos & videos")
                Text("w w w . f e n n e c s t e r e o . c o m")
                    .onTapGesture { viewModel.openWebsite() }
            }
            .foregroundColor(.white)
            .font(.footnote)
            .padding(.bottom, 30)
        }
    }
}

//struct SettingsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SettingsView()
//    }
//}
