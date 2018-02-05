//
//  UserInfoModel.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 22.01.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import Foundation
import CoreData

//    TODO : COMPLETION
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
        
        let request = NSMutableURLRequest(url: self.userinfoURI!)
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        
        request.httpMethod = "GET"
//        request.addValue(, forHTTPHeaderField: <#T##String#>)
        
    }
    
}

extension UserInfoModel : URLSessionDataDelegate {
    
    
}
