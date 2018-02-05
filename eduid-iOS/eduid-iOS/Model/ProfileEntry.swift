//
//  ProfileEntry.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 01.02.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import IGListKit

final class ProfileEntry : NSObject {
    
    var entryKey : String!
    var entryValue : Any!
    
    init(entryKey : String , entryValue : Any) {
        self.entryKey = entryKey
        self.entryValue = entryValue
    }
    
    
}



extension ProfileEntry : ListDiffable {
    func diffIdentifier() -> NSObjectProtocol {
        
        return entryKey as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        
        guard let object = object as? ProfileEntry else { return false}
        
        return object.entryKey == self.entryKey
    }
    
    
}

