//
//  SettingsViewController.swift
//  AlongTheRoad
//
//  Created by Linus Aidan Meyer-Teruel on 9/9/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    let filterData = RestaurantFilterData.sharedInstance
    
    @IBOutlet weak var priceSwitch1Dollar: UISwitch!
    @IBOutlet weak var priceSwitch2Dollar: UISwitch!
    @IBOutlet weak var priceSwitch3Dollar: UISwitch!
    
    @IBOutlet weak var openNowSwitch: UISwitch!
    
    @IBOutlet weak var ratingSegment: UISegmentedControl!
    
    @IBOutlet weak var distanceSlider: UISlider!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.initializeView()

    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func initializeView() {
        
        // initialize price switches
        let prices = filterData.pricesSelcted
        priceSwitch1Dollar.setOn(prices[0], animated: false)
        priceSwitch2Dollar.setOn(prices[1], animated: false)
        priceSwitch3Dollar.setOn(prices[2], animated: false)
        
        // initialize openNow switch
        openNowSwitch.setOn(filterData.openSelected, animated: false)
        
        // initialize rating segment: 7 is the default and corresponds to the 0 index
        let minRating = filterData.minRatingSelected
        ratingSegment.selectedSegmentIndex = minRating - 7
        
    }
    
    @IBAction func priceSwitch1DollarToggled(sender: AnyObject) {
        var prices = filterData.pricesSelcted
        prices[0] = !prices[0]
        filterData.pricesSelcted = prices
    }
    
    @IBAction func priceSwitch2DollarToggled(sender: AnyObject) {
        var prices = filterData.pricesSelcted
        prices[1] = !prices[1]
        filterData.pricesSelcted = prices
    }
    
    @IBAction func priceSwitch3DollarToggled(sender: AnyObject) {
        var prices = filterData.pricesSelcted
        prices[2] = !prices[2]
        filterData.pricesSelcted = prices
    }
    
    @IBAction func openNowSwitchToggled(sender: AnyObject) {
        var openSelected = filterData.openSelected
        openSelected = !openSelected
        filterData.openSelected = openSelected
    }
    
    @IBAction func ratingSegmentSelected(sender: UISegmentedControl) {
        // the minimum rating is the index + 7: 0 -> 7, 1 -> 8, 2 -> 9
        filterData.minRatingSelected = sender.selectedSegmentIndex + 7
    }

}
