//
//  SoundCloudSupply.swift
//  Noise.Supply
//
//  Created by Alan Westbrook on 6/3/15.
//  Copyright (c) 2015 rockwood. All rights reserved.
//

import Foundation
import AVFoundation

let kClientId = "b386da1a67a067584cac1747c49ef3d7"
let kRelatedLimit = 10

class SoundCloudSupply {
    
    var seedText:String = "" {
        didSet {
            beginStream()
        }
    }
    
    var songName:String?
    var userName:String?
    var image:UIImage? {
        didSet {
            // We update the image async, so as not to mess up the UI thread on song changes
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.notifyHandler()
            })
        }
    }
    var playing:Bool = false {
        didSet {
            notifyHandler()
        }
    }
    
    var updateHandler:((supply:SoundCloudSupply) -> Void)?
    
    private var player:AVQueuePlayer?
    private var observer:PlayerStreamObserver?
    private var trackInfo:NSDictionary? {
        didSet {
            handleTrackInfoUpdated()
        }
    }
    private var nextTrackInfo:NSDictionary? {
        didSet {
            pushNextTrackIntoQueue()
        }
    }
    
    func togglePlay() {
        if playing {
            pause()
        }
        else {
            play()
        }
    }
    
    func play() {
        if let playerActual = player {
            playerActual.play()
        }
    }
    
    func pause() {
        if let playerActual = player {
            playerActual.pause()
        }
    }
    
    func next() {
        advancePlayQueue()
    }
    
    private func notifyHandler() {
        if let handlerActual = updateHandler {
            handlerActual(supply:self)
        }
    }
    
    private func beginStream() {
        resolveSeed() { (data) -> Void in
            
            if let jsonData = data {
                if let dict = NSJSONSerialization.JSONObjectWithData(jsonData, options: NSJSONReadingOptions(), error: nil) as? NSDictionary {
                    self.trackInfo = dict
                }
            }
        }
    }
    
    private func handleTrackInfoUpdated() {
        if let dict = trackInfo {
            getNextRelatedTrack()
            
            if player == nil {
                player = AVQueuePlayer(URL: streamUrlFromTrack(dict))
                observer = PlayerStreamObserver(supply: self)
                player?.actionAtItemEnd = .Advance
                player?.play()
            }

            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if let title = dict["title"] as? String {
                    self.songName = title
                }
                
                self.image = nil
                let user = dict["user"] as? NSDictionary
                if let userActual = user {
                    if let username = userActual["username"] as? String {
                        // Sometimes this is actually the album =/
                        self.userName = username
                    }
                }
                
                self.notifyHandler()

                // I feel like the async image retreval interface here has made a right mess
                if let imageURL = dict["artwork_url"] as? String {
                    self.setImageFromBase(imageURL) { Void in                            
                        if self.image == nil, let userActual = user {
                            if let userAvatarURL = userActual["avatar_url"] as? String {
                                self.setImageFromBase(userAvatarURL) { Void in
                                    if self.image == nil {
                                        self.notifyHandler()
                                    }
                                }
                            }
                        }
                    }
                }
                else if let userActual = user {
                    if let userAvatarURL = userActual["avatar_url"] as? String {
                        self.setImageFromBase(userAvatarURL) { Void in
                            if self.image == nil {
                                self.notifyHandler()
                            }
                        }
                    }
                }
            })
        }
    }
    
    private func pushNextTrackIntoQueue() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            if let nextTrack = self.nextTrackInfo, playerActual = self.player {
                let item = AVPlayerItem(URL: self.streamUrlFromTrack(nextTrack))
                    playerActual.insertItem(item, afterItem: nil)
            }    
        })
    }
    
    private func advancePlayQueue() {
        if let playerActual = player {
            playerActual.advanceToNextItem()
        }
    }

    private func streamUrlFromTrack(track:NSDictionary) -> NSURL? {
        
        if let streamValue = track["stream_url"] as? String {
            let credentialValue = "\(streamValue)?client_id=\(kClientId)"
            if let streamURL = NSURL(string: credentialValue) {
                return streamURL
            }
        }
        
        return nil
    }
    
    private func setImageFromBase(base:String, completion:(() -> Void)?) {
        let original = base.stringByReplacingOccurrencesOfString("large", withString: "original", options: NSStringCompareOptions.BackwardsSearch, range: nil)
        
        if let originalURL = NSURL(string: original) {
            setImageFromURL(originalURL) { Void in
                if self.image == nil {
                    let fiveByFive = base.stringByReplacingOccurrencesOfString("large", withString: "t500x500", options: NSStringCompareOptions.BackwardsSearch, range: nil)
                    if let fiveByURL = NSURL(string: fiveByFive) {
                        self.setImageFromURL(fiveByURL, completion: completion)
                    }
                }
                else if let completionActual = completion {
                    completionActual()
                }
            }
        }
        
    }
    
    private func setImageFromURL(url:NSURL, completion:(() -> Void)?) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), { () -> Void in
            if let imageData = NSData(contentsOfURL: url) {
                if let imageActual = UIImage(data: imageData) {
                    self.image = imageActual
                    
                    if let completionActual = completion {
                        completionActual()
                    }
                }
            }
        })
    }
    
    private func resolveSeed(completion:(data:NSData?) -> Void) {
        let normalizedSeed = map(seedText.generate()) {
            $0 == " " ? "+" : $0
        }

        resolve(String(normalizedSeed), completion: completion)
    }
    
    private func resolve(track:String, completion:(data:NSData?) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            if let resolvedData = self.resolveAsTrackURL(track) {
                completion(data: resolvedData)
            } 
            else if let trackActual = self.resolveAsUser(track) {
                self.resolve(trackActual, completion: completion)
            }
            else if let track = self.resolveAsGenre(track) {
                self.resolve(track, completion:completion)    
            }
            else {
                // upsupported?
            }
        })
    }

    private func resolveAsTrackURL(track:String) -> NSData? {
        if let trackURL = NSURL(string: "https://api.soundcloud.com/resolve.json?url=\(track)&client_id=\(kClientId)") {
            return NSData(contentsOfURL: trackURL) 
        }
        return nil
    }
 
    private func resolveAsUser(user:String) -> String? {
        if let userURL = NSURL(string: "https://api.soundcloud.com/users/\(user)/favorites?client_id=\(kClientId)") {
            if let trackData = NSData(contentsOfURL: userURL) {
                if let trackArray = NSJSONSerialization.JSONObjectWithData(trackData, options: NSJSONReadingOptions(), error: nil) as? NSArray {
                    if trackArray.count < 1 {
                        return nil
                    }
                    
                    let randomIndex = Int(arc4random()) % trackArray.count
                    let randTrack = trackArray[randomIndex] as! NSDictionary
                    if let track = randTrack["permalink_url"] as? String {
                        return track
                    }
                }
            }
        }
        
        return nil
    }
    
    private func resolveAsGenre(genre:String) -> String? {
        if let trackURL = NSURL(string: "https://api.soundcloud.com/tracks?tags=\(genre)&limit=100&client_id=\(kClientId)") {
            if let trackData = NSData(contentsOfURL: trackURL) {
                if let trackArray = NSJSONSerialization.JSONObjectWithData(trackData, options: NSJSONReadingOptions(), error: nil) as? NSArray {
                    if var sortedTracks = trackArray as? [NSDictionary] {
                        sortedTracks.sort({ (left, right) -> Bool in
                            return ( left["playback_count"] as! Int ) < ( right["playback_count"] as! Int )
                        })
                        
                        let count = sortedTracks.count > 9 ? 10 : sortedTracks.count
                        
                        if count < 1 {
                            return nil
                        }
                        
                        let randomIndex = Int(arc4random()) % count
                        return sortedTracks[randomIndex]["permalink_url"] as? String
                    }
                }
            }
        }
        return nil
    }
    
    private func getNextRelatedTrack() {
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0), { () -> Void in
            if let info = self.trackInfo {
                if let id = info["id"] as? Int {
                    if let relatedQueryURL = NSURL(string: "https://api.soundcloud.com/tracks/\(id)/related?limit=\(kRelatedLimit)") {
                        if let relatedData = NSData(contentsOfURL: relatedQueryURL) {
                            if let trackArray = NSJSONSerialization.JSONObjectWithData(relatedData, options: NSJSONReadingOptions(), error: nil) as? [NSDictionary] {
                                let randomIndex = Int(arc4random()) % trackArray.count
                                self.nextTrackInfo = trackArray[randomIndex]
                            }
                        }
                    }
                }
            }
        })
    }
}

private class PlayerStreamObserver : NSObject {
    weak var supplier:SoundCloudSupply?
    
    required init(supply:SoundCloudSupply) {
        supplier = supply
        super.init()
        supply.player?.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.New, context: nil)
        supply.player?.addObserver(self, forKeyPath: "currentItem", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    deinit {
        supplier?.player?.removeObserver(self, forKeyPath: "rate")
        supplier?.player?.removeObserver(self, forKeyPath: "currentItem")
    }

    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if let supply = supplier {
            if object === supply.player {
                if keyPath == "rate" {
                    supply.playing = supply.player?.rate > 0
                }
                else if keyPath == "currentItem" {
                    supply.trackInfo = supply.nextTrackInfo
                }
            }
        }
        else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
}


/*

{
"artwork_url" = "<null>";
"attachments_uri" = "https://api.soundcloud.com/tracks/200508770/attachments";
bpm = "<null>";
"comment_count" = 6;
commentable = 1;
"created_at" = "2015/04/12 21:21:35 +0000";
description = "";
"download_count" = 1;
downloadable = 0;
duration = 265690;
"embeddable_by" = all;
"favoritings_count" = 21;
genre = "Melodic Space Metal";
id = 200508770;
isrc = "<null>";
"key_signature" = "<null>";
kind = track;
"label_id" = "<null>";
"label_name" = "<null>";
"last_modified" = "2015/05/24 21:29:57 +0000";
license = "all-rights-reserved";
"original_content_size" = 10779604;
"original_format" = mp3;
permalink = "lost-astronaut";
"permalink_url" = "http://soundcloud.com/yearsinemptiness/lost-astronaut";
"playback_count" = 312;
policy = ALLOW;
"purchase_title" = "<null>";
"purchase_url" = "<null>";
release = "<null>";
"release_day" = 12;
"release_month" = 4;
"release_year" = 2015;
sharing = public;
state = finished;
"stream_url" = "https://api.soundcloud.com/tracks/200508770/stream";
streamable = 1;
"tag_list" = "\"Space Metal\" Metal \"Years In Emptiness\" \"Years In Emptiness Lost Astronaut\" \"Lost Astronaut\" Space Lost \"Fade Away\" Emptiness Vast Heavy Epic Melodic";
title = "Lost Astronaut";
"track_type" = "<null>";
uri = "https://api.soundcloud.com/tracks/200508770";
user =     {
    "avatar_url" = "https://i1.sndcdn.com/avatars-000142821720-yfe9jp-large.jpg";
    id = 22777359;
    kind = user;
    "last_modified" = "2015/04/26 08:10:07 +0000";
    permalink = yearsinemptiness;
    "permalink_url" = "http://soundcloud.com/yearsinemptiness";
    uri = "https://api.soundcloud.com/users/22777359";
    username = "YEARS IN EMPTINESS";
};
"user_id" = 22777359;
"video_url" = "<null>";
"waveform_url" = "https://w1.sndcdn.com/g28AG8iGU51o_m.png";
}

*/


