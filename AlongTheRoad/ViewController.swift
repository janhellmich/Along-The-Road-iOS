//
//  ViewController.swift
//  AlongTheRoad
//
//  Created by Linus Aidan Meyer-Teruel on 8/29/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit
import GoogleMaps

class ViewController: UIViewController, UITextFieldDelegate {

    
    @IBOutlet weak var startingPoint: UITextField!
    @IBOutlet weak var destination: UITextField!
    
    let routeData = RouteDataModel.sharedInstance
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    var placesClient: GMSPlacesClient?
    
    
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
    
    @IBAction func goToAutoComplete(sender: UITextField) {
        // specify whether the destination of origin field is clicked
        if (sender.placeholder == "Destination") {
            routeData.isDestination = true;
        } else {
            routeData.isDestination = false;
        }
        performSegueWithIdentifier("autocomplete", sender: nil)
    }

    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }
    
    @IBAction func submitRoute(sender: AnyObject) {
        
    }
    
    override func viewWillAppear(animated: Bool) {
        startingPoint.text = routeData.startingPoint
        destination.text = routeData.destination
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placesClient = GMSPlacesClient()
        println(placesClient == nil)
        
        routeData.startingPoint = "San Francisco"
        routeData.destination = "Palo Alto"

        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

