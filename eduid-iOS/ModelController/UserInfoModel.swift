//
//  UserInfoModel.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 22.01.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import Foundation
import CoreData

// Currently not used since User Info is delivered directly from the Identity Provider inside id_token at the authentication process (TokenModel).
// TODO: Next feature separation of getting user info after authentication process.
class UserInfoModel : NSObject {
    
    private var userinfoURI : URL?
    private lazy var persistentContainer : NSPersistentContainer? = nil
    private lazy var managedContext : NSManagedObjectContext? = nil
    
    init (userinfoURI : URL? = nil){
        super.init()
        
        self.userinfoURI = userinfoURI
    }

    
    func fetchServer() {
        
        if self.userinfoURI == nil {
            return
        }
        
    }
    
}

extension UserInfoModel : URLSessionDataDelegate {
}
