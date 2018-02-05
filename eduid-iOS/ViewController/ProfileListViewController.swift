//
//  ProfileListViewController.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 01.02.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit
import IGListKit

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
        
        self.profileNameLabel.text = "Hello " + String(describing: jws["given_name"]!) + " " + String(describing: jws["family_name"]!)
        
        for key in (jws.keys) {
            let profile = ProfileEntry(entryKey: key, entryValue: jws[key]!)
            self.id_token.append(profile)
        }
    }
    
    @IBAction func logout(_ sender: Any) {
//        self.performSegue(withIdentifier: "toLogout1", sender: self)
    }
    
}

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
