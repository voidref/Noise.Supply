//
//  ViewController.swift
//  Noise.Supply
//
//  Created by Alan Westbrook on 6/1/15.
//  Copyright (c) 2015 rockwood. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

let kClientId = "b386da1a67a067584cac1747c49ef3d7"

class ViewController: UIViewController {

    @IBOutlet var urlField:UITextField!
    @IBOutlet var playButton:UIButton!
    @IBOutlet var songNameLabel:UILabel!
    @IBOutlet var songDeetsLabel:UILabel!
    
//    private var streamer:AudioStreamer?
    private var player:AVPlayer?
    private var playing:Bool = false {
        didSet {
            playButton.setTitle(playing ? "Pause" : "Play", forState: .Normal)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        urlField.text = "https://soundcloud.com/yearsinemptiness/lost-astronaut"
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func supplyNoiseClicked(sender: UIButton) {
        if playing {
            self.player?.pause()
            playing = false
        }
        else if self.player != nil {
            self.player?.play()
            playing = true
        }
        else if let url = NSURL(string: urlField.text) {
            beginTrackStream(url)
        }
    }
    
    func beginTrackStream(url:NSURL) {
        resolveURL(url, completion: { (data) -> Void in
            
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
                            self.songNameLabel.text = title
                        }
                        
                        if let user = dict["user"] as? NSDictionary {
                            if let username = user["username"] as? String {
                                // Sometimes this is actually the album =/
                                self.songDeetsLabel.text = username
                            }
                        }
                    })
                }
            }
        })
    }
    
    func resolveURL(url:NSURL, completion:(data:NSData?) -> Void) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), { () -> Void in
            let trackURL = NSURL(string: "https://api.soundcloud.com/resolve.json?url=\(url)&client_id=\(kClientId)")!
            if let resolvedData = NSData(contentsOfURL: trackURL) {
                // track
                completion(data: resolvedData)
            } 
            else {
                // User
                let userURL = NSURL(string: "https://api.soundcloud.com/users/\(url)/favorites?client_id=\(kClientId)")!
                if let trackData = NSData(contentsOfURL: userURL) {
                    if let trackArray = NSJSONSerialization.JSONObjectWithData(trackData, options: NSJSONReadingOptions(), error: nil) as? NSArray {
                        let randomIndex = Int(arc4random()) % trackArray.count
                        let randTrack = trackArray[randomIndex] as! String
                        if let url = NSURL(string: randTrack) {
                            self.resolveURL(url, completion: completion)
                        }
                    }
                }
            }
        })
    }
    
    func playStreamWithURL(url:NSURL) {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.player = AVPlayer(URL: url)
            
            self.player?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
            self.player?.addObserver(self, forKeyPath: "rate", options: NSKeyValueObservingOptions.New, context: nil)
            self.player?.play()
//            self.streamer = AudioStreamer(URL: url)
//            self.streamer?.start()
        })
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {
        if object === player {
            if keyPath == "status" {
                if player?.status == .ReadyToPlay {
                    
                }   
            }
            else if keyPath == "rate" {
                playing = player?.rate > 0
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

