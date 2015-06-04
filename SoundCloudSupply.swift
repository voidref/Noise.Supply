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

class SoundCloudSupply {
    
    var seedText:String = "" {
        didSet {
            beginStream()
        }
    }
    
    var songName:String?
    var userName:String?
    var playing:Bool = false {
        didSet {
            notifyHandler()
        }
    }
    
    var updateHandler:((supply:SoundCloudSupply) -> Void)?
    
    private var player:AVPlayer?
    private var observer:PlayerStreamObserver?

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
            playing = true
        }
    }
    
    func pause() {
        if let playerActual = player {
            playerActual.pause()
            playing = false
        }
    }
    
    func next() {
        
    }
    
    func previous() {
        
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
                    println("\(dict)")
                    if let streamValue = dict["stream_url"] as? String {
                        let credentialValue = "\(streamValue)?client_id=\(kClientId)"
                        if let streamURL = NSURL(string: credentialValue) {
                            self.playStreamWithURL(streamURL)
                        }
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        if let title = dict["title"] as? String {
                            self.songName = title
                        }
                        
                        if let user = dict["user"] as? NSDictionary {
                            if let username = user["username"] as? String {
                                // Sometimes this is actually the album =/
                                self.userName = username
                            }
                        }
                        
                        self.notifyHandler()
                    })
                }
            }
        }
    }
    
    private func resolveSeed(completion:(data:NSData?) -> Void) {
        resolve(self.seedText, completion: completion)
    }
    
    private func resolve(track:String, completion:(data:NSData?) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            let trackURL = NSURL(string: "https://api.soundcloud.com/resolve.json?url=\(track)&client_id=\(kClientId)")!
            if let resolvedData = NSData(contentsOfURL: trackURL) {
                // track
                completion(data: resolvedData)
            } 
            else {
                // User
                let userURL = NSURL(string: "https://api.soundcloud.com/users/\(track)/favorites?client_id=\(kClientId)")!
                if let trackData = NSData(contentsOfURL: userURL) {
                    if let trackArray = NSJSONSerialization.JSONObjectWithData(trackData, options: NSJSONReadingOptions(), error: nil) as? NSArray {
                        let randomIndex = Int(arc4random()) % trackArray.count
                        let randTrack = trackArray[randomIndex] as! NSDictionary
                        if let track = randTrack["permalink_url"] as? String {
                            self.resolve(track, completion: completion)
                        }
                    }
                }
            }
        })
    }

    func playStreamWithURL(url:NSURL) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            
            if self.observer != nil {
                self.observer = nil
            }
            
            self.player?.pause()
            
            self.player = AVPlayer(URL: url)            
            self.observer = PlayerStreamObserver(supply: self)
            self.player?.play()
            //            self.streamer = AudioStreamer(URL: url)
            //            self.streamer?.start()
        })
    }
    

}

private class PlayerStreamObserver : NSObject {
    weak var supplier:SoundCloudSupply?
    
    required init(supply:SoundCloudSupply) {
        supplier = supply
        super.init()
        supply.player?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
        supply.player?.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.New, context: nil)
    }
    
    deinit {
        supplier?.player?.removeObserver(self, forKeyPath: "status")
        supplier?.player?.removeObserver(self, forKeyPath: "rate")
    }

    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if object === supplier?.player {
            if keyPath == "status" {
                if supplier?.player?.status == .ReadyToPlay {
                    
                }   
            }
            else if keyPath == "rate" {
                supplier?.playing = supplier?.player?.rate > 0
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


