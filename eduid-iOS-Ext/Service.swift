//
//  Service.swift
//  eduid-iOS-Ext
//
//  Created by Blended Learning Center on 02.02.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import Foundation
import IGListKit

class Service: NSObject {
    var serviceName : [String]
    
    init(_ serviceName: [String]) {
        self.serviceName = serviceName
    }
}

extension Service : ListDiffable {
    public func diffIdentifier() -> NSObjectProtocol {
        return self
    }
    
    public func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        return isEqual(object)
    }
    
}
