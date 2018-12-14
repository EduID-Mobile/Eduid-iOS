//
//  SortingCell.swift
//  eduid-iOS-Ext
//
//  Created by Blended Learning Center on 11.04.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit

//Sorting Cell, currently without sorting function, since it is still not deciced with data that app will get to sort the protocols (ex. Institution information)
class SortingCell: UICollectionViewCell {
    @IBOutlet weak var noneFilterButton: RoundCornerButton!
    
    @IBOutlet weak var servicesFilterButton: RoundCornerButton!
    
    @IBOutlet weak var institutionsFilterButton: RoundCornerButton!
    
    private let selectedFillColor = UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)
    private let selectedTextColor = UIColor.white
    
    private var fillColor : UIColor?
    private var textColor : UIColor?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        fillColor =  noneFilterButton.backgroundColor
        textColor = noneFilterButton.titleLabel?.textColor
        
        noneFilterButton.setTitleColor(selectedTextColor, for: .selected)
        servicesFilterButton.setTitleColor(selectedTextColor, for: .selected)
        institutionsFilterButton.setTitleColor(selectedTextColor, for: .selected)
        noneFilterButton.isSelected = true
        noneFilterButton.backgroundColor = selectedFillColor
 
    }
    
    @IBAction func filter(_ sender: Any) {
        guard let senderBtn = sender as? RoundCornerButton else { return }
        
        if senderBtn == noneFilterButton {
            noneFilterButton.isSelected = true
            noneFilterButton.backgroundColor = selectedFillColor
            servicesFilterButton.isSelected = false
            servicesFilterButton.backgroundColor = fillColor
            institutionsFilterButton.isSelected = false
            institutionsFilterButton.backgroundColor = fillColor
            
        }else if senderBtn == servicesFilterButton {
            
            noneFilterButton.isSelected = false
            noneFilterButton.backgroundColor = fillColor
            servicesFilterButton.isSelected = true
            servicesFilterButton.backgroundColor = selectedFillColor
            institutionsFilterButton.isSelected = false
            institutionsFilterButton.backgroundColor = fillColor
            
        } else {
            
            noneFilterButton.isSelected = false
            noneFilterButton.backgroundColor = fillColor
            servicesFilterButton.isSelected = false
            servicesFilterButton.backgroundColor = fillColor
            institutionsFilterButton.isSelected = true
            institutionsFilterButton.backgroundColor = selectedFillColor
            
        }
        
        
        
    }
    

}
