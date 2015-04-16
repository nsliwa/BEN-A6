//
//  MasterViewController.swift
//  BEN-A6
//
//  Created by Nicole Sliwa on 4/15/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//

import UIKit

class MasterViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

//    @IBAction func onClick_learn(sender: OBShapedButton) {
//        
//        NSLog("click learn")
////        performSegueWithIdentifier("segue_learn", sender: sender)
//        
//    }
//    
//    @IBAction func onClick_predict(sender: OBShapedButton) {
//        
//        NSLog("click predict")
//        performSegueWithIdentifier("segue_predict", sender: sender)
//        
//    }
//    
//    @IBAction func onClick_ask(sender: OBShapedButton) {
//        
//        NSLog("click ask")
//        performSegueWithIdentifier("segue_ask", sender: sender)
//        
//    }
    

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if (segue.identifier == "segue_learn") {
            let vc = segue.destinationViewController as! CaptureViewController
            var predictMode = false
           vc.switchMode = predictMode
            
            NSLog("segue_learn")
        }
        else if (segue.identifier == "segue_predict") {
            let vc = segue.destinationViewController as! CaptureViewController
            var predictMode = true
            vc.switchMode = predictMode
            
            NSLog("segue_predict")
        }
        else if (segue.identifier == "segue_ask") {
            let vc = segue.destinationViewController as! AskViewController
            NSLog("segue_ask")
            
        }
        NSLog("segue")
        
    }


}
