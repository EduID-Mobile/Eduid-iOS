//
//  ConsentCell.swift
//  eduid-iOS-Ext
//
//  Created by Blended Learning Center on 30.10.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit
import BEMCheckBox

//Consent Cell that will pop out for every service selected
class ConsentCell : ServiceSingleTonCell {
    
    @IBOutlet weak var consentLabel: UILabel!
    //@IBOutlet weak var serviceLabel: UILabel!
    //@IBOutlet weak var switchButton: BEMCheckBox!
    @IBOutlet weak var iconImageView: UIImageView!
    
    override func awakeFromNib() {
        let frame = CGRect(x: self.frame.origin.x, y: consentLabel.frame.origin.y, width: self.frame.size.width - 40, height: consentLabel.frame.size.height)
        
        let backgroundConsent = UIView(frame: frame)
        backgroundConsent.isOpaque = false
        backgroundConsent.layer.cornerRadius = 10
        backgroundConsent.clipsToBounds = true
        backgroundConsent.backgroundColor = UIColor(red:0.00, green:0.48, blue:0.75, alpha:1.0)
        backgroundConsent.alpha = 0.1
        addSubview(backgroundConsent)
        bringSubview(toFront: backgroundConsent)
    }
}
