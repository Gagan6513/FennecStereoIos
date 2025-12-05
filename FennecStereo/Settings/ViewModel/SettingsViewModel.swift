//
//  SettingsViewModel.swift
//  FennecStereo
//
//  Created by Kushkumar on 08/10/25.
//

import SwiftUI
import Combine
// MARK: - Toggle Item Model
struct SettingToggleItem: Identifiable {
    let id = UUID()
    let title: String
    let binding: Binding<Bool>
    let tintColor: Color
}

enum Border: String {
    
    case offBlack = "Off Black"
    case black = "Black"
    case white = "White"
    case offWhite = "Off White"
    case backGround = "Background"
    
    static func color(border: Border) -> Color {
        
        switch border {
        case .offBlack:
            return Color("offBlack_222222")
        case .black:
            return Color.black
        case .white:
            return Color.white
        case .offWhite:
            return Color("offWhite_DDDDDD")
        case .backGround:
            return Color("backgroun_1B1B1B")
        }
    }
}



//
//final class SettingsViewModel: ObservableObject {
//    // MARK: - Published Properties
//    @Published var separatePhotos = false
//    @Published var shutterSound = false
//    @Published var level = false
//    @Published var border = true
//    @Published var fuseDotGuide = true
//    @Published var grid = true
//    @Published var selectedBorderColor: String = Border.offBlack.rawValue
//    
//    let borderOptions: [String] = [
//        Border.offBlack.rawValue,
//        Border.black.rawValue,
//        Border.white.rawValue,
//        Border.offWhite.rawValue
//    ]
//    
//     init() {
//        
//         self.initialSetup()
//    }
//    
//    func initialSetup() {
//        
//        print("fsdfsdfdsfdsf")
//        
//        if let separatePhotos = UserDefaults.standard.separatePhotos {
//            self.separatePhotos = separatePhotos
//        }
//        
//        if let shutterSound = UserDefaults.standard.shutterSound {
//            self.shutterSound = shutterSound
//        }
//        
//        if let level = UserDefaults.standard.level {
//            self.level = level
//        }
//        
//        if let border = UserDefaults.standard.border {
//            self.border = border
//        }
//        
//        if let borderName = UserDefaults.standard.borderName {
//            self.selectedBorderColor = borderName
//        }
//        
//        if let fuseDotGuide = UserDefaults.standard.fuseDotGuide {
//            self.fuseDotGuide = fuseDotGuide
//        }
//        
//        if let grid = UserDefaults.standard.grid {
//            self.grid = grid
//        }
//    }
//    
//    
//    // MARK: - Actions
//    func openInstagram() {
//        AppUtils.shared.hapticEffect()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            AppUtils.openURL(AppConstant.instagramUrl)
//        }
//    }
//    
//    func openYouTube() {
//        AppUtils.shared.hapticEffect()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            AppUtils.openURL(AppConstant.youtubeUrl)
//        }
//    }
//    
//    func openWebsite() {
//        AppUtils.shared.hapticEffect()
//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
//            AppUtils.openURL("https://fennecstereo.com/")
//        }
//    }
//}


