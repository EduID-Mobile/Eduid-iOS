//
//  ProfileListViewController.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 01.02.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit
import IGListKit
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
        
        logoutBtn.backgroundColor = UIColor.black
        logoutBtn.titleLabel!.textColor = UIColor.white
    }
    
    func loadEntries() {
        guard let jws = token!.giveIdTokenJWS() else {return}
        if (jws["given_name"] == nil) && (jws["family_name"] == nil) {
            self.profileNameLabel.text = "Hello"
        } else {
            self.profileNameLabel.text = "Hello " + String(describing: jws["given_name"]!) + " " + String(describing: jws["family_name"]!)
        }
        for key in (jws.keys) {
            if key == "given_name" || key == "family_name" {
                continue
            }
            let profile = ProfileEntry(entryKey: key, entryValue: jws[key]!)
            self.id_token.append(profile)
        }
    }
    
    @IBAction func logout(_ sender: Any) {
        // Perform segue if the logout button is tapped,
        // This has been set up already inside the storyboard.
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier != "toLogout"  {
            return
        }
        guard let logoutVC = segue.destination as? LogoutViewController else {return}
        logoutVC.tokenModel = self.token
    }
    
}

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
