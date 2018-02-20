//
//  SearchCell.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 19.02.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit

final class SearchCell: UICollectionViewCell, UISearchBarDelegate {
    
    lazy var searchBar : UISearchBar = {
        let view = UISearchBar()
        self.contentView.addSubview(view)
        return view
    }()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        searchBar.frame = contentView.bounds
        
        let gesture = UISwipeGestureRecognizer(target: self, action: #selector(gestureSwipedDown(_:)))
        gesture.direction = .down
        self.superview?.addGestureRecognizer(gesture)
        
    }
    
    @IBAction func gestureSwipedDown(_ sender: UISwipeGestureRecognizer){
        if self.searchBar.isFirstResponder{
            self.endEditing(true)
        }
    }
}
