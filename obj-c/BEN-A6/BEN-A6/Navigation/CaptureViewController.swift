//
//  CaptureViewController.swift
//  BEN-A6
//
//  Created by Nicole Sliwa on 4/8/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//

import UIKit

class CaptureViewController: UIViewController, NSURLSessionTaskDelegate {
    
    @IBOutlet weak var switch_mode: UISwitch!
    
    let SERVER_URL = "http://nicoles-macbook-pro.local:8000"
    let UPDATE_INTERVAL = 1/10.0
    
    var session: NSURLSession! = nil
    var taskID = 0
    
    var capturedImage: UIImage! = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func onClick_toggleFlash(sender: UIButton) {
    }
    
    @IBAction func onToggle_modeSwitch(sender: UISwitch) {
    }
    
    @IBAction func onClick_captureImage(sender: UIButton) {
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
