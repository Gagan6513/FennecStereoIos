//
//  Constant.swift
//  DiscoverMe

import Foundation
import SwiftUI

/// General object of UserDefaults
let USER_DEFAULTS = UserDefaults.standard
/// General object of UIApplication
let APPLICATION = UIApplication.shared

class AppConstant {
    
    static let youtubeUrl = "https://youtube.com/@fennecstereo?si=nq8E3iyU-ptsC8rw"
    static let instagramUrl = "https://www.instagram.com/fennecstereo?igsh=MTB6aTA3bXZ5OXRnaA=="
}

extension UserDefaults {
    private enum SettingsKeys {
        static let separatePhotos = "SeparatePhotos"
        static let shutterSound = "ShutterSound"
        static let level = "Level"
        static let border = "Border"
        static let borderName = "BorderName"
        static let fuseDotGuide = "FuseDotGuide"
        static let grid = "Grid"
        static let rotate = "Rotate"
        static let flash = "Flash"
    }

    var separatePhotos: Bool? {
        get { self[SettingsKeys.separatePhotos] }
        set { self[SettingsKeys.separatePhotos] = newValue }
    }
    
    var shutterSound: Bool? {
        get { self[SettingsKeys.shutterSound] }
        set { self[SettingsKeys.shutterSound] = newValue }
    }
    
    var level: Bool? {
        get { self[SettingsKeys.level] }
        set { self[SettingsKeys.level] = newValue }
    }
    
    var border: Bool? {
        get { self[SettingsKeys.border] }
        set { self[SettingsKeys.border] = newValue }
    }
    
    var borderName: String? {
        get { self[SettingsKeys.borderName] }
        set { self[SettingsKeys.borderName] = newValue }
    }
    
    var fuseDotGuide: Bool? {
        get { self[SettingsKeys.fuseDotGuide] }
        set { self[SettingsKeys.fuseDotGuide] = newValue }
    }
    
    var grid: Bool? {
        get { self[SettingsKeys.grid] }
        set { self[SettingsKeys.grid] = newValue }
    }
    
    var rotate: Bool? {
        get { self[SettingsKeys.rotate] }
        set { self[SettingsKeys.rotate] = newValue }
    }
    
    var flash: Bool? {
        get { self[SettingsKeys.flash] }
        set { self[SettingsKeys.flash] = newValue }
    }
    
}

extension UserDefaults {
    
    subscript<T>(key: String) -> T? {
        get {
            return value(forKey: key) as? T
        } set {
            set(newValue, forKey: key)
        }
    }
    
    subscript<T: RawRepresentable>(key: String) -> T? {
        get {
            if let rawValue = value(forKey: key) as? T.RawValue {
                return T(rawValue: rawValue)
            }
            return nil
        } set {
            set(newValue?.rawValue, forKey: key)
        }
    }
}
