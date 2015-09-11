//
//  SettingsViewController.swift
//  AlongTheRoad
//
//  Created by Linus Aidan Meyer-Teruel on 9/9/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    let restaurantData = RestaurantDataModel.sharedInstance
    @IBOutlet weak var priceOutlet: UISegmentedControl!
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
//    @IBAction func priceSelection(sender: UISegmentedControl) {
//        switch priceOutlet.selectedSegmentIndex {
//            case 0:
//                restaurantData.priceFilter = nil
//            case 1:
//                restaurantData.priceFilter = 1
//            case 2:
//                restaurantData.priceFilter = 2
//            case 3:
//                restaurantData.priceFilter = 3 
//            default:
//                break;
//        }
//    }
    
}
