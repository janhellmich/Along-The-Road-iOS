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
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()

        return false
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if var mapScene = segue.destinationViewController as? GoogleMapViewController {
            mapScene.destination = self.destination.text
            mapScene.startingPoint = self.startingPoint.text
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

