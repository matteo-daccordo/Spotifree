//
//  DataManager.swift
//  Spotifree
//
//  Created by Eneas Rotterdam on 29.12.15.
//  Copyright © 2015 Eneas Rotterdam. All rights reserved.
//

import Cocoa

let KEY_MENU_BAR_ICON_HIDDEN = "SFMenuBarIconHidden"
let KEY_SHOW_NOTIFICATIONS = "SFShowNotifications"
let KEY_POLLING_RATE = "SFPollingRate"

class DataManager : NSObject {
    static let sharedData = DataManager()
    
    private let appleScriptCmds = NSDictionary(contentsOfFile: Bundle.main.path(forResource: "AppleScriptCmds", ofType: "plist")!)!
    
    override init() {
        super.init()
        
        if isInLoginItems() && !isLoginItemPathCorrect() {
            removeLoginItem()
            addLoginItem()
        }
        
        let defaults = [KEY_MENU_BAR_ICON_HIDDEN : false, KEY_SHOW_NOTIFICATIONS : false, KEY_POLLING_RATE : 0.3] as [String : Any]
        UserDefaults.standard.register(defaults: defaults)
        
        if !UserDefaults.standard.bool(forKey: "SUHasLaunchedBefore") {
            addLoginItem()
        }
    }
    
    func pollingRate() -> Double {
        return UserDefaults.standard.double(forKey: KEY_POLLING_RATE)
    }
    
    func isMenuBarIconHidden() -> Bool {
        return UserDefaults.standard.bool(forKey: KEY_MENU_BAR_ICON_HIDDEN)
    }
    
    func setMenuBarIconHidden(_ hidden : Bool) {
        UserDefaults.standard.set(hidden, forKey: KEY_MENU_BAR_ICON_HIDDEN)
        UserDefaults.standard.synchronize()
    }
    
    func toggleLoginItem() {
        isInLoginItems() ? removeLoginItem() : addLoginItem()
    }
    
    func addLoginItem() {
        NSAppleScript(source: String(format: appleScriptCmds["addLoginItem"] as! String, Bundle.main.bundlePath))?.executeAndReturnError(nil)
    }
    
    func removeLoginItem() {
        NSAppleScript(source: appleScriptCmds["removeLoginItem"] as! String)?.executeAndReturnError(nil)
    }
    
    
    func isInLoginItems() -> Bool{
        var isInItems = true
        let desc = NSAppleScript(source: appleScriptCmds["isInLoginItems"] as! String)?.executeAndReturnError(nil)
        if let desc = desc {
            isInItems = desc.booleanValue
        }
        return isInItems
    }
    
    func isLoginItemPathCorrect() -> Bool {
        var isCorrect = true
        let desc = NSAppleScript(source: String(format: appleScriptCmds["isLoginItemPathCorrect"] as! String, Bundle.main.bundlePath))?.executeAndReturnError(nil)
        if let desc = desc {
            isCorrect = desc.booleanValue
        }
        return isCorrect
    }
    
    func toggleShowNotifications() {
        let showNotifications = UserDefaults.standard.bool(forKey: KEY_SHOW_NOTIFICATIONS)
        UserDefaults.standard.set(!showNotifications, forKey: KEY_SHOW_NOTIFICATIONS)
        UserDefaults.standard.synchronize()
    }
    
    func shouldShowNofifications() -> Bool {
        return UserDefaults.standard.bool(forKey: KEY_SHOW_NOTIFICATIONS)
    }
}
