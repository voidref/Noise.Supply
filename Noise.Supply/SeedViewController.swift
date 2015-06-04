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
        if let seedText = seedField.text {
            supply.seedText = seedField.text
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
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return "none"
    }
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
}


