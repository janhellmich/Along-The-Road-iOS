//
//  AutocompleteViewController.swift
//  AlongTheRoad
//
//  Created by Jan Hellmich on 9/4/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit

class AutocompleteViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var placesClient: GMSPlacesClient?
    
    let routeData = RouteDataModel.sharedInstance
    
    var suggestions: [String] = []

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var locationField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placesClient = GMSPlacesClient()
        
        // make the text field the first responder to allow immediate typing
        locationField.becomeFirstResponder()
        
        // set the title based on if it is destination or origin
        if routeData.isDestination {
            self.title = "Set Destination"
        } else {
            self.title = "Set Origin"
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    @IBAction func getSuggestions(sender: UITextField) {
        if count(sender.text!) > 1 {
            placesClient?.autocompleteQuery(sender.text!, bounds: nil, filter: nil, callback: { (results, error: NSError?) -> Void in
                if let error = error {
                    println("Autocomplete error \(error)")
                } else {
                    var newSuggestions: [String] = []
                    for result in results! {
                        if let result = result as? GMSAutocompletePrediction {
                            newSuggestions.append(result.attributedFullText.string)
                        }
                    }
                    self.suggestions = newSuggestions
                    self.tableView.reloadData()
                }
            
            })
        }
        
    }

    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return suggestions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = UITableViewCell();
        cell.textLabel?.text = suggestions[indexPath.row]
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let currentCell = tableView.cellForRowAtIndexPath(indexPath)
        let location = currentCell?.textLabel?.text
        if routeData.isDestination {
            routeData.destination = location!
        } else {
            routeData.startingPoint = location!
        }
        self.navigationController?.popViewControllerAnimated(true)
    }


}
