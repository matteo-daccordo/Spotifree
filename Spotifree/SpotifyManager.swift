//
//  SpotifyManager.swift
//  Spotifree
//
//  Created by Eneas Rotterdam on 29.12.15.
//  Copyright © 2015 Eneas Rotterdam. All rights reserved.
//

import Cocoa
import ScriptingBridge

let fakeAds = false

enum SFSpotifreeState {
    case active
    case muting
    case inactive
}

protocol SpotifyManagerDelegate {
    func spotifreeStateChanged(_ state: SFSpotifreeState)
}
// Optional Functions
extension SpotifyManagerDelegate {
    func spotifreeStateChanged(_ state: SFSpotifreeState) {}
}

class SpotifyManager: NSObject {
    var delegate : SpotifyManagerDelegate?
    
    private static let appleScriptSpotifyPrefix = "tell application \"Spotify\" to "
    
    private var timer : Timer?
    
    private let spotify = SBApplication(bundleIdentifier: "com.spotify.client")! as SpotifyApplication
    
    private var isMuted = false
    private var oldVolume = 75
    
    private var state = SFSpotifreeState.inactive {
        didSet {
            delegate?.spotifreeStateChanged(state)
        }
    }
    
    func start() {
        DistributedNotificationCenter.default().addObserver(self, selector: #selector(SpotifyManager.playbackStateChanged(_:)), name: NSNotification.Name(rawValue: "com.spotify.client.PlaybackStateChanged"), object: nil);
        
        if NSRunningApplication.runningApplications(withBundleIdentifier: "com.spotify.client").count != 0 && spotify.playerState! == .playing {
            checkForAd()
        }
    }
    
    @objc func playbackStateChanged(_ notification : Notification) {
        let playerState = notification.userInfo!["Player State"] as! String
        debugPrint("State " + playerState)
        switch playerState {
            case "Stopped":
                state = .inactive
                fallthrough
            case "Paused":
                state = .active
            case "Playing":
                checkForAd()
            case _: break
        }
    }
    
    @objc func checkForAd() {
        state = .active
        let isAd = getCurrentSongSpotifyURL().starts(with: "spotify:ad")
        debugPrint(isAd ? getCurrentSongSpotifyURL() : "")
        isAd ? mute() : unmute()
    }
    
    func getCurrentSongSpotifyURL() -> String {
        return runAppleScript(script: SpotifyManager.appleScriptSpotifyPrefix + "(get spotify url of current track)")
    }
    
    /**
     * Runs the given apple script and passes logs to completion handler
     */
    func runAppleScript(script: String) -> String {
        let process = Process()
        process.launchPath = "/usr/bin/osascript"
        process.arguments = ["-e", script]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        process.launch()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.availableData
        return String(data: data, encoding: String.Encoding.utf8)!
    }
    
//    func startPolling() {
//        if (timer != nil) {return}
//        timer = Timer.scheduledTimer(timeInterval: DataManager.sharedData.pollingRate(), target: self, selector: #selector(SpotifyManager.checkForAd), userInfo: nil, repeats: true)
//        timer!.fire()
//
//        state = .active
//    }
    
//    func stopPolling() {
//        if let timer = timer {
//            timer.invalidate()
//            self.timer = nil
//            state = isMuted ? .muting : .inactive
//        }
//    }
    
    func mute() {
        state = .muting
        oldVolume = (spotify.soundVolume)!
        
//      stopPolling()
        
        spotify.pause!()
        spotify.setSoundVolume!(0);
        spotify.play!()
        
        if DataManager.sharedData.shouldShowNofifications() {
            var duration = 0
            duration = spotify.currentTrack!.duration! / 1000 * 2
            displayNotificationWithText(String(format: NSLocalizedString("NOTIFICATION_AD_DETECTED", comment: "Notification: A Spotify ad was detected! Music will be back in about %i seconds…"), duration))
        }
    }
    
    func unmute() {
        state = .active
        delay(3/4) {
            self.isMuted = false
            self.spotify.setSoundVolume!(self.oldVolume)
        }
    }
    
    func displayNotificationWithText(_ text : String) {
        let notification = NSUserNotification()
        notification.title = "Spotifree"
        notification.informativeText = text
        notification.soundName = nil
        
        NSUserNotificationCenter.default.deliver(notification)
    }
    
    func delay(_ delay:Double, closure:@escaping ()->()) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
}
