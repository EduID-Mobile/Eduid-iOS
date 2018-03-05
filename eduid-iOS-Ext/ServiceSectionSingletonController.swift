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

class ServiceSectionSingletonController: ListSectionController {

    private weak var entry : Service!
    private weak var token : TokenModel!
    private weak var protocolsModel : ProtocolsModel!
    private weak var authToken : AuthorizationTokenModel!
    private var audience : String!
    private var sessionKeys : [String: Key]!
    
    init(entry : Service, token: TokenModel, protocolsModel : ProtocolsModel, authToken : AuthorizationTokenModel, aud : String, sessionKeys : [String: Key]){
        super.init()
        self.entry = entry
        self.token = token
        self.audience = aud
        self.sessionKeys = sessionKeys
        self.protocolsModel = protocolsModel
        self.authToken = authToken
    }
    
    override func numberOfItems() -> Int {
        if entry == nil {
            return 0
        }
        return entry.serviceName.count
    }
    
    override func sizeForItem(at index: Int) -> CGSize {
        //TODO: MAKE HEIGHT RELATIVE
        return CGSize(width: collectionContext!.containerSize.width - 20 , height: 50)
    }
    
    override func cellForItem(at index: Int) -> UICollectionViewCell {
        guard let cell = collectionContext?.dequeueReusableCell(withNibName: "ServiceSingletonCell", bundle: nil, for: self, at: index) as? ServiceSingleTonCell else{
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
        guard let adress = self.protocolsModel.getApisLink(serviceName: self.entry.serviceName[index]), let homeLink = self.protocolsModel.getHomepageLink(serviceName: self.entry.serviceName[index]) else {
            print("no apis found")
            return
        }
        
        authRequest(adress: adress, homepageLink: homeLink)
    }
    
    func authRequest(adress : URL , homepageLink : String){
        
        
        print(self.token?.giveAccessToken()! as Any)
        let idToken = self.token?.giveTokenID()?.last
        print(self.token?.giveTokenID()?.first! as Any)
        print(self.token?.giveTokenID()?.last! as Any)
        let assert = authToken.createAssert(addressToSend: adress.absoluteString, subject: idToken!["sub"] as! String, audience: self.audience , accessToken: (token?.giveAccessToken()!)!, kidToSend: (self.sessionKeys!["public"]?.getKid())! , keyToSign: self.sessionKeys!["private"]!)
        print("ASSERT : \(assert!)")
        
        guard let vc = self.viewController as? ServiceViewController else{
            print("error getting view controller on request method")
            return
        }
        vc.showLoadUI()
        authToken.fetch(address: adress, assertionBody: assert!)
    }
    
    
}
