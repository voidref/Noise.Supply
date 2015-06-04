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

let kGenres = [            
    "Alternative Rock",
    "Ambient",
    "Blues",
    "Chill",
    "Chiptune",
    "Classical",
    "Country",
    "Dance & EDM",
    "Dancehall",
    "Deep House",
    "Deep Tropical",
    "Disco",
    "Drake",
    "Dream Pop",
    "Drum & Bass",
    "Dubstep",
    "Electro House",
    "Electronic",
    "Experimental",
    "Folk & Singer-Songwriter",
    "Future",
    "Future House",
    "Glitch Hop",
    "Glitterwave",
    "Glo-Fi",
    "Hip Hop & Rap",
    "House",
    "Indie Pop",
    "Indie Rock",
    "Jazz",
    "Latin",
    "Metal",
    "Noise",
    "Noise Pop",
    "Piano",
    "Pop",
    "Progressive House",
    "R&B & Soul",
    "Reggae",
    "Reggaeton",
    "Rock",
    "Shoegaze",
    "Soundtrack",
    "Techno",
    "Trance",
    "Trap",
    "Trip Hop",
    "Tropical House",
    "Twee",
    "Witch House",
    "World",
    "Vaporwave"
]

class SeedViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet var seedField:UITextField!
    @IBOutlet var picker:UIPickerView!
    
    var supply = SoundCloudSupply()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        seedField.text = "https://soundcloud.com/yearsinemptiness/lost-astronaut"
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
        if seedField.text != ""  {
            supply.seedText = seedField.text
        }
        else {
            supply.seedText = kGenres[picker.selectedRowInComponent(0)] 
        }
    } 
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let songvc = segue.destinationViewController as? SongViewController {
            songvc.supply = supply
        }
        
        super.prepareForSegue(segue, sender: sender)
    }
    
    // MARK: - UIPicker-ness
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return kGenres.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return kGenres[row]
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
}


