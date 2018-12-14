//
//  SearchSectionController.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 19.02.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit
import IGListKit

protocol SearchSectionControllerDelegate : class {
    func searchSectionController(_ sectionController: SearchSectionController, didChangeText text: String )
}

class SearchSectionController : ListSectionController, UISearchBarDelegate, ListScrollDelegate {
    
    weak var delegate : SearchSectionControllerDelegate?
    
    override init(){
        super.init()
        scrollDelegate = self
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        return CGSize(width: collectionContext!.containerSize.width, height: 50)
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let cell = collectionContext?.dequeueReusableCell(of: SearchCell.self, for: self, at: index) as? SearchCell else {
            fatalError()
        }
        cell.searchBar.delegate = self
        return cell
    }
    
    //    MARK: Search Bar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        delegate?.searchSectionController(self, didChangeText: searchText)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        delegate?.searchSectionController(self, didChangeText: searchBar.text!)
        searchBar.superview?.endEditing(true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        delegate?.searchSectionController(self, didChangeText: searchBar.text!)
        searchBar.superview?.endEditing(true)
    }
    
    //    MARK:  LIST SCROLL DELEGATE
    func listAdapter(_ listAdapter: ListAdapter, didScroll sectionController: ListSectionController) {
        if let searchCell = collectionContext?.cellForItem(at: 0, sectionController: self) as? SearchCell{
            let searchBar = searchCell.searchBar
            searchBar.resignFirstResponder()
        }
    }
    
    func listAdapter(_ listAdapter: ListAdapter, willBeginDragging sectionController: ListSectionController) {}
    
    func listAdapter(_ listAdapter: ListAdapter, didEndDragging sectionController: ListSectionController, willDecelerate decelerate: Bool) {}
}
