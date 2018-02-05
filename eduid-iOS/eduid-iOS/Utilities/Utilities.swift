//
//  Utilities.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 31.01.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

//import Foundation
import UIKit

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
    
}

extension NSString{
    
    func height(withConstrainedWidth width: CGFloat, font : UIFont) -> CGFloat {
        
        let contraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: contraintRect, options: .usesLineFragmentOrigin, attributes: [.font : font], context: nil)
        return ceil(boundingBox.height)
    }
    
}
