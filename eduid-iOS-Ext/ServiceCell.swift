//
//  ServiceCell.swift
//  eduid-iOS-Ext
//
//  Created by Blended Learning Center on 02.02.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit

class ServiceCell: UICollectionViewCell {

    
    @IBOutlet weak var serviceLabel: UILabel!
    
    private var service : String?{
        get{
            return serviceLabel.text
        }
        set {
            serviceLabel.text = newValue
        }
    }

}
