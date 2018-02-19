//
//  ProfileEntry.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 01.02.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import IGListKit
/**
 A simple model which is required to generate a cell for the table view (IGListKit).
 This class simply holds the required data to be shown on the cell view.
 */
final class ProfileEntry : NSObject {
    
    var entryKey : String!
    var entryValue : Any!
    
    init(entryKey : String , entryValue : Any) {
        self.entryKey = entryKey
        self.entryValue = entryValue
    }
    
    
}


//Model object should be a subclass from ListDiffable (IGListKit requirement)
extension ProfileEntry : ListDiffable {
    func diffIdentifier() -> NSObjectProtocol {
        
        return entryKey as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        
        guard let object = object as? ProfileEntry else { return false}
        
        return object.entryKey == self.entryKey
    }
    
    
}

