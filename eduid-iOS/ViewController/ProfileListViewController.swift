//
//  ProfileListViewController.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 01.02.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit
import IGListKit
import JWTswift

/**
 This ViewController would be called directly if the login process is successfull.
 Used to show the user her/his personal data, that are registered on the server
 Mostly this view just show the response data from the server, which is contained inside the TokenModel instance.
 ## Functions :
 - Show the personal data from the server.
 
 */
class ProfileListViewController: UIViewController {
    
    @IBOutlet weak var profileNameLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var logoutBtn: UIButton!
    
    var textLabel : String?
    var token : TokenModel?
    var id_token : [ProfileEntry] = []
    
    lazy var adapter : ListAdapter = {
        return ListAdapter(updater: ListAdapterUpdater(), viewController: self)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if token == nil {
            return
        }
        
        loadEntries()
        self.collectionView.collectionViewLayout = UICollectionViewFlowLayout()
        
        adapter.collectionView =  collectionView
        adapter.dataSource = self
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier != "toLogout"  {
            return
        }
        guard let logoutVC = segue.destination as? LogoutViewController else {return}
        logoutVC.tokenModel = self.token
    }
    
    //MARK: -- Set Functions
    func loadEntries() {
        guard let jws = token!.giveIdTokenJWS() else {return}
        if (jws["given_name"] == nil) && (jws["family_name"] == nil) {
            self.profileNameLabel.text = "Hello"
        } else {
            self.profileNameLabel.text = "Hello \n" + String(describing: jws["given_name"]!) + " " + String(describing: jws["family_name"]!)
        }
        for key in (jws.keys) {
            /*
             if key == "given_name" || key == "family_name" {
             continue
             }*/
            if key == "email" || key == "iss" {
                let profile = ProfileEntry(entryKey: key, entryValue: jws[key]!)
                self.id_token.append(profile)
            }
        }
    }
    
    @IBAction func logout(_ sender: Any) {
        showAlertLogout()
    }
    
    func showAlertLogout(){
        let logoutTitle = "Warning"
        let logoutText = "Logging out means also that all app authorizations will be rejected"
        let cancelText = "Cancel"
        let confirmText = "Confirm"
        
        let alert = UIAlertController(title: logoutTitle, message: logoutText, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cancelText, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: confirmText,
                                      style: .default,
                                      handler: {(alertaction) in
                                        self.confirmLogout()}
                                    )
                        )
        let viewGray = UIView(frame: self.view.frame)
        viewGray.tag = 1
        viewGray.backgroundColor = UIColor.gray.withAlphaComponent(0.5)
        self.view.addSubview(viewGray)
        self.present(alert, animated: true, completion: {
            viewGray.removeFromSuperview()
        })
    }
    
    func confirmLogout(){
        self.token?.deleteAll()
        let root = self.navigationController?.viewControllers.first as! LoginViewController
        root.tokenModel?.deleteAll()
        guard let keypair =  KeyChain.loadKeyPair(tagString: "sessionKey") else{
            print("Key pair is not found")
            return
        }
        
        if KeyChain.deleteKeyPair(tagString: "sessionKey", keyPair: keypair) {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    func showAlertUI(){
        let errorMsg = NSLocalizedString("ErrorLogout", comment: "error text for the log out")
        let tryagainText = NSLocalizedString("TryAgain", comment: "Try again text")
        let closeText = NSLocalizedString("Close", comment: "Close text")
        
        let alert = UIAlertController(title: "Error", message: errorMsg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: tryagainText, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: closeText, style: .default, handler: { (alertAction) in
            UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
        }))
        
        
        self.present(alert, animated: true, completion: nil)
        
    }
}

//MARK: -- ListAdapterSource(Delegate)
// Handle the adapter delegate for the ig list kit
extension ProfileListViewController : ListAdapterDataSource{
    func objects(for listAdapter: ListAdapter) -> [ListDiffable] {
        return self.id_token as [ListDiffable]
    }
    
    func listAdapter(_ listAdapter: ListAdapter, sectionControllerFor object: Any) -> ListSectionController {
        return ProfileSectionController(entry: object as! ProfileEntry)
    }
    
    func emptyView(for listAdapter: ListAdapter) -> UIView? {
        print("in emptyView Function")
        return nil
    }
}
