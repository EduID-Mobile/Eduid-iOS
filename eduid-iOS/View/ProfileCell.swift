//
//  ProfileCell.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 01.02.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit

class ProfileCell: UICollectionViewCell {

    @IBOutlet weak var keyLabel: UILabel!
    @IBOutlet weak var valueLabel: UILabel!
    
    private var keyStr : String?{
        get{
            return keyLabel.text
        }
        set {
            keyLabel.text = newValue
        }
    }
    
    private var valueStr : String? {
        get{
            return valueLabel.text
        }
        set {
            valueLabel.text = newValue
        }
    }
    
}
