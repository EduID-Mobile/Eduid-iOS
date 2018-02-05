//
//  ProfileSectionController.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 01.02.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import Foundation
import IGListKit

final class ProfileSectionController : ListSectionController {
    
    private var entry : ProfileEntry!
    
    init(entry : ProfileEntry) {
        super.init()
        self.entry = entry
//        inset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    
    override func numberOfItems() -> Int {
        return 1
    }
    
    override func didUpdate(to object: Any) {
        print("DID UPDATE")
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        return CGSize(width: collectionContext!.containerSize.width - 20, height: 60)
        
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        
        guard let cell = collectionContext?.dequeueReusableCell(withNibName: "ProfileCell", bundle: nil, for: self, at: index) as? ProfileCell else{ fatalError()}
        
        cell.keyLabel.text = entry?.entryKey!
        print(entry)
        if(entry.entryValue != nil) {
            cell.valueLabel.text = String(describing: entry!.entryValue!)
        }
//        Border on top side of the cell
        let border = CALayer()
        border.backgroundColor = UIColor.gray.cgColor
        border.frame = CGRect(x: 0, y: cell.frame.size.height - 1.0, width: cell.frame.size.width, height: 1.0)
        cell.layer.addSublayer(border)
        return cell
    }
    
    override func didSelectItem(at index: Int) {
        print("select : \(index)")
    }
    
}

