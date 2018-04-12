//
//  SortSectionController.swift
//  eduid-iOS-Ext
//
//  Created by Blended Learning Center on 12.04.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit
import IGListKit

class SortSectionController: ListSectionController {

    
    override init(){
        super.init()
    }
    
    override func numberOfItems() -> Int {
        return 1
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        //guard let cell = collectionContext?.dequeueReusableCellFromStoryboard(withIdentifier: "SortingCell", for: self, at: index) as? SortingCell else {
        //    fatalError()
        //}
        guard let cell = collectionContext?.dequeueReusableCell(withNibName: "SortingCell", bundle: nil, for: self, at: index) as? SortingCell else {
            fatalError()
        }
        return cell
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        return CGSize(width: collectionContext!.containerSize.width, height: 60)
    }
    
    
    
}
