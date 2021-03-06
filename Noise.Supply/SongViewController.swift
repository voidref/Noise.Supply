//
//  SongViewController.swift
//  Noise.Supply
//
//  Created by Alan Westbrook on 6/3/15.
//  Copyright (c) 2015 rockwood. All rights reserved.
//

import UIKit

let kPlaceholderImageName = "Noise.supply"
class SongViewController: UIViewController {

    @IBOutlet var playButton:UIButton!
    @IBOutlet var songNameLabel:UILabel!
    @IBOutlet var songDeetsLabel:UILabel!
    @IBOutlet var backgroundImage:UIImageView!
    @IBOutlet var mainImage:UIImageView!
    @IBOutlet var vfxView:UIVisualEffectView!

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
        supply?.togglePlay()
    }

    @IBAction func nextClicked(sender: UIButton) {
        supply?.next()
    }
    
    func handleSupplyUpdate(supply:SoundCloudSupply) {
        playButton.setTitle(supply.playing ? "Pause" : "Play", forState: .Normal)
        songNameLabel.text = supply.songName
        songDeetsLabel.text = supply.userName
        
        if let imageActual = supply.image {
            
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.backgroundImage.image = imageActual

                if imageActual.size.width < self.backgroundImage.image?.size.width {
                    self.mainImage.alpha = 1
                    self.vfxView.alpha = 1
                    self.mainImage.image = imageActual
                }
                else {
                    self.mainImage.alpha = 0
                    self.vfxView.alpha = 0
                }
            })
        }
        else {
//            UIView.animateWithDuration(0.3, animations: { () -> Void in
//                self.mainImage.alpha = 1
//                self.vfxView.alpha = 1
//                self.mainImage.image = UIImage(named: kPlaceholderImageName)
//                self.backgroundImage.image = self.mainImage.image
//            })
        }
    }
}
