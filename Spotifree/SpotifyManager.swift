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
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(self.playbackStateChanged(_:)),
            name: NSNotification.Name(rawValue: "com.spotify.client.PlaybackStateChanged"),
            object: nil);
        checkSong()
    }
    
    @objc func playbackStateChanged(_ notification : Notification) {
        let playerState = notification.userInfo!["Player State"] as! String
        debugPrint(notification)
        debugPrint("State " + playerState)
        switch playerState {
            case "Stopped":
                fallthrough
            case "Paused":
                stopPolling()
            case "Playing":
                startPolling()
            case _: break
        }
        checkSong()
    }
    
    @objc func checkSong() {
        state = .active
        let songURL = getCurrentSongSpotifyURL()
        debugPrint(songURL)
        let isSong = songURL.starts(with: "spotify:track")
        debugPrint(isSong)
        
        isSong ? unmute() : mute()
    }
    
    func startPolling() {
        if (timer != nil) {return}
        timer = Timer.scheduledTimer(
                timeInterval: DataManager.sharedData.pollingRate(),
                target: self,
                selector: #selector(SpotifyManager.checkSong),
                userInfo: nil,
                repeats: true
        )
        timer!.fire()
    }
    
    func stopPolling() {
        if let timer = timer {
            timer.invalidate()
            self.timer = nil
        }
    }
    
    /**
    * Restart current song
    */
    func restartSong(){
        _ = runAppleScript(script: SpotifyManager.appleScriptSpotifyPrefix + "(play previous track)")
    }
    
    /**
    * Returns current song duration in seconds
    */
    func getCurrentSongDuration() -> Double {
        return (runAppleScript(script: SpotifyManager.appleScriptSpotifyPrefix + "(get duration of current track)") as NSString).doubleValue / 1000
    }
    
    /**
    * Returns current song URL
    */
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
    
    func mute() {
        spotify.pause!()
        self.spotify.setSoundVolume!(0);
        self.isMuted = true
        spotify.play!()
    }
    
    func unmute() {
        state = .active
        delay(3/4) {
            self.isMuted = false
            self.spotify.setSoundVolume!(100)
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
