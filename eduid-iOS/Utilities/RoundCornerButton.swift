//
//  RoundCornerButton.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 10.04.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit

class RoundCornerButton: LocalizedButton {

    @IBInspectable var radius : Int = 0 {
        didSet{
            self.layer.cornerRadius = CGFloat(radius)
            self.clipsToBounds = true
        }
    }
    
}
