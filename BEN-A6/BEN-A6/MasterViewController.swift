//
//  MasterViewController.swift
//  BEN-A6
//
//  Created by Nicole Sliwa on 4/15/15.
//  Copyright (c) 2015 Team B.E.N. All rights reserved.
//

import UIKit

class MasterViewController: UIViewController, NSURLSessionTaskDelegate {
    //UI elements
    
    @IBOutlet weak var button_learn: OBShapedButton!
    @IBOutlet weak var button_predict: OBShapedButton!
    @IBOutlet weak var button_ask: OBShapedButton!
    
    @IBOutlet weak var button_add: UIButton!
    @IBOutlet weak var button_update: UIButton!
    
    
    // session config
    //    let SERVER_URL: NSString = "http://guests-mac-mini-2.local:8000"
    var SERVER_URL: NSString = "http://nicoles-macbook-pro.local:8000"
    let UPDATE_INTERVAL = 1/10.0
    
    var session: NSURLSession! = nil
    var taskID = 0
    var dsid = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        var defaultDict: NSDictionary?
        if let path = NSBundle.mainBundle().pathForResource("AppInfo", ofType: "plist") {
            defaultDict = NSDictionary(contentsOfFile: path)
        }
        if let dict = defaultDict {
            NSUserDefaults.standardUserDefaults().registerDefaults(dict as [NSObject : AnyObject])
        }
        
        //setup NSURLSession (ephemeral)
        let sessionConfig: NSURLSessionConfiguration = NSURLSessionConfiguration.ephemeralSessionConfiguration()
        
        sessionConfig.timeoutIntervalForRequest = 5.0;
        sessionConfig.timeoutIntervalForResource = 8.0;
        sessionConfig.HTTPMaximumConnectionsPerHost = 1;
        
        session = NSURLSession(configuration: sessionConfig, delegate: self, delegateQueue: nil)
        
        
        
        let defaults = NSUserDefaults.standardUserDefaults()
        if let serverURL = defaults.stringForKey("Server_URL") {
            SERVER_URL = serverURL
        }
        
//        if let id = defaults.integerForKey("dsid") as Int? {
//            dsid = id
//        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        getCurrentDSID()
    }


    func getCurrentDSID() {
        // Add a data point and a label to the database for the current dataset ID
        
        button_learn.userInteractionEnabled = false
        button_predict.userInteractionEnabled = false
        button_ask.userInteractionEnabled = false
        button_add.userInteractionEnabled = false
        button_update.userInteractionEnabled = false
        
        // setup the url
        var baseURL: NSString = NSString(format: "%@/GetCurrentDatasetId",SERVER_URL)
        
        var postURL: NSURL = NSURL(string: baseURL as String)!
        
        // data to send in body of post request (send arguments as json)
        var error: NSError?
        
        // create a custom HTTP POST request
        var request: NSMutableURLRequest = NSMutableURLRequest(URL: postURL)
        
        request.HTTPMethod = "GET"
        
        // start the request, print the responses etc.
        let postTrack: NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: { ( data:NSData!, response:NSURLResponse!, err:NSError! ) -> Void in
            if(err == nil) {
                NSLog("response: %@", response)
                NSLog("data: %@",  NSString(data: data, encoding: NSUTF8StringEncoding)!)
                
                if let responseData: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary {
                    
                    if let results: Int = (responseData.valueForKey("dsid") as? Int) {
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.dsid = results
                            
                            let defaults = NSUserDefaults.standardUserDefaults()
                            defaults.setInteger(results, forKey: "dsid")
                            
                            if let id = defaults.integerForKey("dsid") as Int? {
                                NSLog("saved dsid: %d", id)
                            }
                            
                        }
                    } else { NSLog("error parsing json") }
                } else { NSLog("error getting json") }
            } else { NSLog("error with connection") }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.button_learn.userInteractionEnabled = true
                self.button_predict.userInteractionEnabled = true
                self.button_ask.userInteractionEnabled = true
                self.button_add.userInteractionEnabled = true
                self.button_update.userInteractionEnabled = true
            }
            
        })
        
        postTrack.resume()
    }
    
    
    
    @IBAction func onClick_newDSID(sender: UIButton) {
        
        button_learn.userInteractionEnabled = false
        button_predict.userInteractionEnabled = false
        button_ask.userInteractionEnabled = false
        button_add.userInteractionEnabled = false
        button_update.userInteractionEnabled = false
        
        // setup the url
        var baseURL: NSString = NSString(format: "%@/GetNewDatasetId",SERVER_URL)
        
        var postURL: NSURL = NSURL(string: baseURL as String)!
        
        // data to send in body of post request (send arguments as json)
        var error: NSError?
        
        // create a custom HTTP POST request
        var request: NSMutableURLRequest = NSMutableURLRequest(URL: postURL)
        
        request.HTTPMethod = "GET"
        
        // start the request, print the responses etc.
        let postTrack: NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: { ( data:NSData!, response:NSURLResponse!, err:NSError! ) -> Void in
            if(err == nil) {
                NSLog("response: %@", response)
                NSLog("data: %@",  NSString(data: data, encoding: NSUTF8StringEncoding)!)
                
                if let responseData: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary {
                    
                    if let results: Int = (responseData.valueForKey("dsid") as? Int) {
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.dsid = results
                            
                            let defaults = NSUserDefaults.standardUserDefaults()
                            defaults.setInteger(results, forKey: "dsid")
                            
                            if let id = defaults.integerForKey("dsid") as Int? {
                                NSLog("saved dsid: %d", id)
                            }
                            
                        }
                    } else { NSLog("error parsing json") }
                } else { NSLog("error getting json") }
            } else { NSLog("error with connection") }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.button_learn.userInteractionEnabled = true
                self.button_predict.userInteractionEnabled = true
                self.button_ask.userInteractionEnabled = true
                self.button_add.userInteractionEnabled = true
                self.button_update.userInteractionEnabled = true
            }
            
        })
        
        postTrack.resume()
        
    }
    
    @IBAction func onclick_updateModel(sender: UIButton) {
        
        button_learn.userInteractionEnabled = false
        button_predict.userInteractionEnabled = false
        button_ask.userInteractionEnabled = false
        button_add.userInteractionEnabled = false
        button_update.userInteractionEnabled = false
        
        // setup the url
        var baseURL: NSString = NSString(format: "%@/LearnLocation?dsid=%d",SERVER_URL, dsid)
        
        var postURL: NSURL = NSURL(string: baseURL as String)!
        
        // data to send in body of post request (send arguments as json)
        var error: NSError?
        var jsonUpload: NSDictionary = ["dsid":dsid]
        
        let requestBody: NSData! = NSJSONSerialization.dataWithJSONObject(jsonUpload, options: NSJSONWritingOptions.PrettyPrinted, error: &error)
        
        // create a custom HTTP POST request
        var request: NSMutableURLRequest = NSMutableURLRequest(URL: postURL)
        
        
        request.HTTPMethod = "GET"
//        request.HTTPBody = requestBody
        
        // start the request, print the responses etc.
        let postTrack: NSURLSessionDataTask = session.dataTaskWithRequest(request, completionHandler: { ( data:NSData!, response:NSURLResponse!, err:NSError! ) -> Void in
            if(err == nil) {
                NSLog("response: %@", response)
                NSLog("data: %@",  NSString(data: data, encoding: NSUTF8StringEncoding)!)
                
                if let responseData: NSDictionary = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: nil) as? NSDictionary {
                    
                    if let results: NSNumber = (responseData.valueForKey("resubAccuracy") as? NSNumber) {
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            NSLog("Accuracy: %f", results)
                            
                        }
                    } else { NSLog("error parsing json") }
                } else { NSLog("error getting json") }
            } else { NSLog("error with connection") }
            
            dispatch_async(dispatch_get_main_queue()) {
                self.button_learn.userInteractionEnabled = true
                self.button_predict.userInteractionEnabled = true
                self.button_ask.userInteractionEnabled = true
                self.button_add.userInteractionEnabled = true
                self.button_update.userInteractionEnabled = true
            }
            
        })
        
        postTrack.resume()
        
    }
    
    
    

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
            let vc = segue.destinationViewController as! WPMainViewController
            NSLog("segue_ask")
            
        }
        NSLog("segue")
        
    }


}
