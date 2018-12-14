//
//  Utilities.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 31.01.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit

//Extension to make a circle UIImage
extension UIImage {
    
    func roundedImageWithBorder (width : CGFloat , color: UIColor) -> UIImage? {
        
        let square = CGSize(width: min(size.width, size.height) + width * 2 , height: min(size.width, size.height) + width * 2)
        let imageView = UIImageView(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: square))
        imageView.contentMode = .center
        imageView.image = self
        imageView.layer.cornerRadius = square.width / 2
        imageView.layer.borderWidth = width
        imageView.layer.borderColor = color.cgColor
        UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil}
        imageView.layer.render(in: context)
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return result
    }
    
    class func imageWithColor(color : UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 1, height: 1), false, 0)
        color.setFill()
        UIRectFill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return image
    }
    
}

//Helper function to get the height of an nsstring
extension NSString{
    
    func height(withConstrainedWidth width: CGFloat, font : UIFont) -> CGFloat {
        
        let contraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: contraintRect, options: .usesLineFragmentOrigin, attributes: [.font : font], context: nil)
        return ceil(boundingBox.height)
    }
    
}

//Simple method to convert possible boolean string into real boolean value
extension String {
    
    func toBool() -> Bool? {
        let lowSelf = self.lowercased()
        switch lowSelf{
        case "true", "yes", "1" :
            return true
        case "false", "no", "0" :
            return false
        default:
            return nil
        }
    }
    
}
