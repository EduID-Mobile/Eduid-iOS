//
//  SplashViewController.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 11.01.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit
import NVActivityIndicatorView

class SplashViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
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
        
        configModel?.downloadedSuccess.bind (listener: { (dlBool) in
            DispatchQueue.main.async{
                self.checkDownload(downloaded: dlBool)
            }
        })
        configModel?.fetchServer()
        downloadConfig()
        
    }
    
    func setUI(){
        indicator = NVActivityIndicatorView(frame: CGRect(x: self.view.center.x,
                                                          y: self.view.center.y,
                                                          width: self.view.bounds.width / 5, height: self.view.bounds.height / 7))
        indicator!.color = UIColor(red: 85/255, green: 146/255, blue: 193/255, alpha: 1.0)
        indicator!.type = .lineScaleParty
        indicator.isHidden = false
        indicator.center = self.view.center
        self.view.insertSubview(indicator, belowSubview: titleLabel)
    }
    
    func checkDownload(downloaded : Bool?){
        
        print("checkDownload in SplashViewController : \( String(describing:downloaded) ) ")
        if downloaded == nil || !downloaded! {
            
            self.showAlertUI()
            
            
            return
        }
        
        downloadFinished()
        
    }
    
    func loadPlist(){
        if let path = Bundle.main.path(forResource: "Setting", ofType: "plist") {
            if let dic = NSDictionary(contentsOfFile: path) as? [String : Any] {
                self.reqUrl = URL(string: (dic["ConfigURL"] as? String)!)
                
            }
        }
    }
    
    func downloadConfig() {
        
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
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK: - Navigation
    
    func downloadFinished () {
        let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginVC")
        let navController = UINavigationController.init(rootViewController: loginVC!)
        navController.navigationBar.isHidden = true
        self.present(navController, animated: true, completion: nil)
        
    }
    
    func showBusyUI() {
        self.indicator!.startAnimating()
    }
    
    func hideBusyUI() {
        self.indicator!.stopAnimating()
    }
    
    func showAlertUI(){
        
        let alert = UIAlertController(title: "Timeout", message: "Please check your internet connection and reopen the app", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Try Again", style: .default, handler: { (alertAction) in
            self.configModel?.fetchServer()
        }))
        alert.addAction(UIAlertAction(title: "Close", style: .default, handler: { (alertAction) in
            UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
        }))
        self.present(alert, animated: true, completion: nil)
        
    }
    
}
