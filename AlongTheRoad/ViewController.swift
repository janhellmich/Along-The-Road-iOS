//
//  ViewController.swift
//  AlongTheRoad
//
//  Created by Linus Aidan Meyer-Teruel on 8/29/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var startingPoint: UITextField!
    @IBOutlet weak var destination: UITextField!
    
    let routeData = RouteDataModel.sharedInstance
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return false
    }
    
    
    /* function: prepareForSegue
     * --------------------------
     * This function prepares the next viewcontroller for the segue. It does this by setting the d
     *
     *
    */
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let mapScene = segue.destinationViewController as? MapViewController {
            routeData.destination = "350 5th Avenue New York NY 10118" //self.destination.text
            routeData.startingPoint = "55 East 52nd Street New York NY 10022"// self.startingPoint.text
        }
        
    }
    

    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }
    
    @IBAction func submitRoute(sender: AnyObject) {
        println(self.startingPoint.text)
        println(self.destination.text)
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

