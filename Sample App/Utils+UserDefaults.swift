//
//  Utils+UserDefaults.swift
//
//

import Foundation

struct Defaults {
    
    private static let progamIDKeyUserDefaults = "com.livelike.SampleApp.programID"
    private static let accessTokenKeyUserDefaults = "com.livelike.SampleApp.accessToken"
    private static let programClientID = "com.livelike.SampleApp.clientID"
    private static let walletAddressID = "com.livelike.SampleApp.walletAddressID"

    public static var walletAddress: String? {
        get {
            return UserDefaults.standard.string(forKey: walletAddressID)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: walletAddressID)
            UserDefaults.standard.synchronize()
        }
    }
    
    public static var activeProgramID: String? {
        get {
            return UserDefaults.standard.string(forKey: progamIDKeyUserDefaults)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: progamIDKeyUserDefaults)
            UserDefaults.standard.synchronize()
        }
    }
    
    public static var activeClientID: String? {
        get {
            return UserDefaults.standard.string(forKey: programClientID)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: programClientID)
            UserDefaults.standard.synchronize()
        }
    }
    
    public static var userAccessToken: String? {
        get {
            return UserDefaults.standard.string(forKey: accessTokenKeyUserDefaults)
        }
        set(newValue) {
            UserDefaults.standard.set(newValue, forKey: accessTokenKeyUserDefaults)
            UserDefaults.standard.synchronize()
        }
    }
    
    public static func reset() {
        self.activeProgramID = ""
        self.userAccessToken = nil
    }
}

