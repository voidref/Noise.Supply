//
//  SongViewController.swift
//  Noise.Supply
//
//  Created by Alan Westbrook on 6/3/15.
//  Copyright (c) 2015 rockwood. All rights reserved.
//

import UIKit

class SongViewController: UIViewController {

    @IBOutlet var playButton:UIButton!
    @IBOutlet var songNameLabel:UILabel!
    @IBOutlet var songDeetsLabel:UILabel!

    var supply:SoundCloudSupply? {
        didSet {
            supply?.updateHandler = handleSupplyUpdate
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let supplyActual = supply {
            handleSupplyUpdate(supplyActual)
        }
    }
    
    @IBAction func playClicked(sender: UIButton) {
        if let supplyActual = supply {
            supplyActual.togglePlay()
        }
    }

    func handleSupplyUpdate(supply:SoundCloudSupply) {
        playButton.setTitle(supply.playing ? "Pause" : "Play", forState: .Normal)
        songNameLabel.text = supply.songName
        songDeetsLabel.text = supply.userName
    }
}
