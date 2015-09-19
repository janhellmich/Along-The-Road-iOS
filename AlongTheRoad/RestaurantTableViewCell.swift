//
//  RestaurantTableViewCell.swift
//  AlongTheRoad
//
//  Created by Linus Aidan Meyer-Teruel on 9/5/15.
//  Copyright (c) 2015 Linus Aidan Meyer-Teruel. All rights reserved.
//

import UIKit

class RestaurantTableViewCell: UITableViewCell {
    
    @IBOutlet weak var restaurantPhoto: UIImageView!
    @IBOutlet weak var restaurantName: UILabel!
    @IBOutlet weak var rating: UILabel!
    @IBOutlet weak var priceRange: UILabel!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var openUntil: UILabel!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var category: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
