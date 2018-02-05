//
//  ServiceSectionController.swift
//  eduid-iOS-Ext
//
//  Created by Blended Learning Center on 02.02.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit
import IGListKit
import JWTswift

class ServiceSectionController: ListSectionController {

    private var entry : Service!
    private var token : TokenModel!
    private var audience : String!
    private var sessionKeys : [String: Key]!
    
    init(entry : Service, token: TokenModel, aud : String, sessionKeys : [String: Key]){
        super.init()
        self.entry = entry
        self.token = token
        self.audience = aud
        self.sessionKeys = sessionKeys
    }
    
    override func numberOfItems() -> Int {
        return entry.serviceName.count
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        return CGSize(width: collectionContext!.containerSize.width - 20 , height: 50)
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let cell = collectionContext?.dequeueReusableCell(withNibName: "ServiceCell", bundle: nil, for: self, at: index) as? ServiceCell else{
            fatalError()
        }
        
        
        cell.serviceLabel.text = entry.serviceName[index]
    
        let border = CALayer()
        border.backgroundColor = UIColor.gray.cgColor
        border.frame = CGRect(x: 0, y: cell.frame.size.height - 1.0, width: cell.frame.size.width, height: 1.0)
        cell.layer.addSublayer(border)
        
        return cell
    }
    
    override func didSelectItem(at index: Int) {
        print("did select item : \(index)")
    }
    
    func authRequest(adress : URL , homepageLink : String){
        
        let authToken = AuthorizationTokenModel()
        print(self.token?.giveAccessToken()! as Any)
        let idToken = self.token?.giveTokenID()?.last
        print(self.token?.giveTokenID()?.first! as Any)
        print(self.token?.giveTokenID()?.last! as Any)
        let assert = authToken.createAssert(addressToSend: adress.absoluteString, subject: idToken!["sub"] as! String, audience: self.audience , accessToken: (token?.giveAccessToken()!)!, kidToSend: (self.sessionKeys!["public"]?.getKid())! , keyToSign: self.sessionKeys!["private"]!)
        print("ASSERT : \(assert!)")
        
        authToken.fetch(address: adress, assertionBody: assert!)
    }
    
    
}
