//
//  AutocompleteViewController.swift
//  AlongTheRoad
//
//  Created by Jan Hellmich on 9/4/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit

class AutocompleteViewController: UIViewController, UITableViewDelegate, UITableViewDataSource
 {
    
    var placesClient: GMSPlacesClient?
    
    let routeData = RouteDataModel.sharedInstance
    
    var suggestions: [String] = []

    @IBOutlet weak var tableView: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        placesClient = GMSPlacesClient()

        // Do any additional setup after loading the view.
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

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
