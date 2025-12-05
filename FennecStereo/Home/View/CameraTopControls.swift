//
//  CameraTopControls.swift
//  FennecStereo
//
//  Created by Kushkumar on 08/10/25.
//
import SwiftUI

enum TopOptionsTitle: String {
    case flash = "Flash"
    case anaglyph = "Anaglyph"
    case sbs = "SBS"
    case wigglegram = "Wigglegram"
    case settings = "Settings"
    case crop = "Crop"
}

struct CameraTopControls: View {
    @ObservedObject var vm: HomeViewModel

    var body: some View {
        let width = UIScreen.main.bounds.width / 4

        HStack(spacing: 0) {
            
            if vm.firstImage != nil && vm.secondImage != nil {
                Button { vm.toggleCrop() } label: {
                    CameraTopButton(icon: "crop", title: TopOptionsTitle.crop.rawValue, isHighlighted: vm.isCropOn)
                        .frame(width: width)
                }
            } else {
                Button { vm.toggleFlash() } label: {
                    CameraTopButton(icon: "bolt.fill", title: TopOptionsTitle.flash.rawValue, isHighlighted: vm.isFlashOn)
                        .frame(width: width)
                }
            }
            
            if vm.isWigglegramOn {
                Button { vm.toggleSBS() } label: {
                    CameraTopButton(icon: "ic_anaglyph",
                                    title: TopOptionsTitle.anaglyph.rawValue)
                        .frame(width: width)
                }
            } else {
                if vm.isAnaglyphOn {
                    Button { vm.toggleSBS() } label: {
                        CameraTopButton(icon: "ic_anaglyph",
                                        title: TopOptionsTitle.anaglyph.rawValue)
                            .frame(width: width)
                    }
                } else {
                    Button { vm.toggleAnaglyph() } label: {
                        CameraTopButton(icon:"ic_sbs",
                                        title: TopOptionsTitle.sbs.rawValue)
                            .frame(width: width)
                    }
                }
            }
            
            
            Button { vm.toggleWigglegram() } label: {
                CameraTopButton(icon: "ic_wigglegram", title: TopOptionsTitle.wigglegram.rawValue, isHighlighted: vm.isWigglegramOn)
                    .frame(width: width)
            }

            NavigationLink(destination: SettingsView(viewModel: vm)) {
                CameraTopButton(icon: "gearshape.fill", title: TopOptionsTitle.settings.rawValue)
                    .frame(width: width)
            }
        }
        //.padding(.vertical, 8)
        //.background(.ultraThinMaterial)
        //.clipShape(Capsule())
        //.shadow(color: .black.opacity(0.5), radius: 10, y: 3)
        //.padding(.horizontal)
    }
}
