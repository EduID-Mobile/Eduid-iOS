//
//  GradientView.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 10.04.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import Foundation
import UIKit

final class GradientView : UIView {
    
    @IBInspectable var startColor: UIColor = UIColor.clear
    @IBInspectable var endColor: UIColor = UIColor.clear
    
    override func draw(_ rect: CGRect) {
        let gradient : CAGradientLayer = CAGradientLayer()
        gradient.frame = CGRect(x: CGFloat(0), y: CGFloat(0), width: rect.size.width, height: rect.size.height)
        gradient.colors = [startColor.cgColor , endColor.cgColor]
        gradient.zPosition = -1
        layer.addSublayer(gradient)
        print("DRAWED")
    }
}
