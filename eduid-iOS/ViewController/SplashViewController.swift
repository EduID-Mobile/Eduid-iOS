//
//  SplashViewController.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 11.01.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

/**
 The first screen of the app.
 EduidConfigModel would be used as the core function of this view.
 
 ## Functions:
 - The configuration data will be fetched on this screen and if successful this screen would call the LoginViewController automatically
 */
class SplashViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    
    private var indicator : NVActivityIndicatorView!
    
    var configModel : EduidConfigModel?
    private var reqUrl : URL?
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setUI()
        self.loadPlist()
        configModel = EduidConfigModel(serverUrl: reqUrl)
        
        //        NotificationCenter.default.addObserver(self, selector: #selector(appearFromBackground), name: NSNotification.Name.UIApplicationWillEnterForeground , object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.hideBusyUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.showBusyUI()
        
        configModel?.deleteAll()
        //Set the callback function if the download process has ended
        configModel?.downloadedSuccess.bind (listener: { (dlBool) in
            DispatchQueue.main.async{
                self.checkDownload(downloaded: dlBool)
            }
        })
        configModel?.fetchServer()
        downloadConfig()
        
    }
    
    // MARK: -- Set functions
    
    func checkDownload(downloaded : Bool?){
        
        print("checkDownload in SplashViewController : \( String(describing:downloaded) ) ")
        if downloaded == nil || !downloaded! {
            
            self.showAlertUI()
            
            return
        }
        
        downloadFinished()
    }
    
    func downloadFinished () {
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2){
            
            guard let tokenEndpoint = self.configModel?.getTokenEndpoint() else {
                self.showAlertUI()
                return
            }
            let tokenModel = TokenModel(tokenURI: tokenEndpoint)
            
            let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginVC")
            let navController = UINavigationController.init(rootViewController: loginVC!)
            navController.navigationBar.isHidden = true
            
            if tokenModel.fetchDatabase() {
                guard let profileVC = self.storyboard?.instantiateViewController(withIdentifier: "ProfileVC") as? ProfileListViewController else{return }
                profileVC.token = tokenModel
                navController.pushViewController(profileVC, animated: true)
            }
            
            self.present(navController, animated: true, completion: nil)
            
        }
    }
    
    func loadPlist(){
        if let path = Bundle.main.path(forResource: "Setting", ofType: "plist") {
            if let dic = NSDictionary(contentsOfFile: path) as? [String : Any] {
                self.reqUrl = URL(string: (dic["ConfigURL"] as? String)!)
            }
        }
    }
    
    //DEPRECATED : using listener instead
    private func downloadConfig() {
        
        /* MANUAL TIMEOUT OPTION WITH TIMER
         configModel?.fetchServer()
         var timeoutCounter = 0
         let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timerTmp in
         timeoutCounter += 1
         print(timeoutCounter)
         if (!true)  {
         timerTmp.invalidate()
         self.downloadFinished()
         } else if timeoutCounter == 4 {
         self.showAlertUI()
         timerTmp.invalidate()
         }
         }
         timer.fire()
         */
    }
    
    // MARK: - UI functions
    func setUI(){
        /*
         indicator = NVActivityIndicatorView(frame: CGRect(x: self.view.center.x,
         y: self.view.center.y,
         width: self.view.bounds.width / 5, height: self.view.bounds.height / 7))
         indicator!.color = UIColor(red: 85/255, green: 146/255, blue: 193/255, alpha: 1.0)
         indicator!.type = .lineScaleParty
         indicator.isHidden = false
         indicator.center = self.view.center
         self.view.insertSubview(indicator, belowSubview: titleLabel)
         */
    }
    
    func showAlertUI(){
        
        let alertmessage = NSLocalizedString("TimeoutMessage", comment: "Message appears on the connection timeout")
        let tryagainText = NSLocalizedString("TryAgain", comment: "Try again text")
        let closeText = NSLocalizedString("Close", comment: "Close text")
        
        let alert = UIAlertController(title: "Timeout", message: alertmessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: tryagainText , style: .default, handler: { (alertAction) in
            self.configModel?.fetchServer()
        }))
        alert.addAction(UIAlertAction(title: closeText, style: .default, handler: { (alertAction) in
            UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func showBusyUI() {
        //self.indicator!.startAnimating()
        UIView.animate(withDuration: 1.0, delay: 0, options: [.autoreverse, .repeat, .curveEaseInOut], animations: {
            self.imageView.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
        }, completion: { finished in
            self.imageView.transform = CGAffineTransform(scaleX: 1, y: 1)
        })
        
    }
    
    func hideBusyUI() {
        //self.indicator!.stopAnimating()
        imageView.layer.removeAllAnimations()
    }
    
    
}
