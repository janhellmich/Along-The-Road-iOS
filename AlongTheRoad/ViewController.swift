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
            routeData.destination = "944 Market Street, San Francisco, CA 94102" //self.destination.text
            routeData.startingPoint = "658 Escondido Road, Stanford, CA, 94305"// self.startingPoint.text
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

