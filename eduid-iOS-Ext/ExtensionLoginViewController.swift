//
//  ExtensionLoginViewController.swift
//  eduid-iOS-Ext
//
//  Created by Blended Learning Center on 23.01.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit
import JWTswift
import TextFieldEffects
import NVActivityIndicatorView

/**
 An intial view controller of the extension app.
 This view controller is working with the EduidConfigModel, and TokenModel.
 
 ## Functions:
 - The configuration data will be fetched first from the server
 - After the config data is successfully fetched, user could interact with the UI to enter the login data
 - Manage the Login process, if the user hasn't logged in yet
 */
class ExtensionLoginViewController: UIViewController {

    @IBOutlet weak var usernameTF: IsaoTextField! //UITextField!
    @IBOutlet weak var passwordTF: IsaoTextField! //UITextField!
    @IBOutlet weak var imageView : UIImageView!
    @IBOutlet weak var backgroundView : UIImageView!
    private var indicator : NVActivityIndicatorView!
    
    private var reqConfigUrl : URL?
    private var userDev : String?
    private var passDev : String?
    
    private var tokenEnd: URL?
    private var signingKey : Key?
    private var sessionKey : [String : Key]?
    
    private var configmodel : EduidConfigModel?
    var tokenModel : TokenModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setUIelements()
            
        self.loadPlist()
        
        let keystore = KeyStore()
        
        //assume if there isn't any session key yet, config data is also unavailable
        if !checkSessionKey() {
            
            //create a pair & save if it's not exist yet
            sessionKey = KeyStore.generateKeyPair(keyType: kSecAttrKeyTypeRSA as String)!
            let x = KeyChain.saveKeyPair(tagString: "sessionKey", keyPair: sessionKey!)
            print("Save new key : \(x)")
        }
        
        self.checkConfig()
        
        
        var urlPathKey = Bundle.main.url(forResource: "ios_priv", withExtension: "jwks")
        let keyID = keystore.getPrivateKeyIDFromJWKSinBundle(resourcePath: (urlPathKey?.relativePath)!)
        urlPathKey = Bundle.main.url(forResource: "ios_priv", withExtension: "pem")
        guard let privateKeyID = keystore.getPrivateKeyFromPemInBundle(resourcePath: (urlPathKey?.relativePath)!, identifier: keyID!) else {
            print("ERROR getting private key")
            return
        }
        
        //key object always save the kid in base64url
        signingKey = keystore.getKey(withKid: privateKeyID)!
        
    }
    
    func setUIelements(){
        
//        backgroundView.loadGif(name: "testGif")
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        imageView.clipsToBounds = true
        imageView.image = UIImage(named: "appicontest")//?.roundedImageWithBorder(width: 10, color: UIColor.black)
        imageView.layer.cornerRadius = imageView.layer.frame.width / 2
        
        
        usernameTF.inactiveColor = UIColor.gray
        passwordTF.inactiveColor = UIColor.gray
        usernameTF.activeColor = UIColor(red: 85/255, green: 146/255, blue: 193/255, alpha: 1.0)
        passwordTF.activeColor = UIColor(red: 85/255, green: 146/255, blue: 193/255, alpha: 1.0)
        
        //usernameTF.placeholder = "Username"
        //passwordTF.placeholder = "Password"
        
        usernameTF.delegate = self
        passwordTF.delegate = self
        
        indicator = NVActivityIndicatorView(frame: CGRect(x: self.view.center.x,
                                                          y: self.view.center.y,
                                                          width: self.view.bounds.width / 5, height: self.view.bounds.height / 7))
        indicator!.color = UIColor(red: 85/255, green: 146/255, blue: 193/255, alpha: 1.0)
        indicator!.type = .lineScaleParty
        indicator.isHidden = false
        indicator.center = self.view.center
        
    }

    @objc func keyboardWillShow(){
        self.view.frame.origin.y = -150 //move upward 150
    }
    
    @objc func keyboardWillHide(){
        self.view.frame.origin.y = 0
    }

    @IBAction func login(_ sender: Any) {
        guard let userSub : String = usernameTF.text , let pass : String  = passwordTF.text else{
            return
        }
        
        showLoadUI()
        
        tokenModel?.downloadSuccess.bind (listener: { (dlBool) in
            DispatchQueue.main.async {
                self.checkDownload(downloaded: dlBool)
            }
        })
        
        let userAssert = tokenModel?.createUserAssert(userSub: userSub, password: pass, issuer: userDev!, audience: (configmodel?.getIssuer())!, keyToSend: sessionKey!["public"]!, keyToSign: signingKey!)
        
        do{
            try tokenModel?.fetchServer(username: userDev!, password: passDev!, assertionBody: userAssert!)
        } catch {
            print(error.localizedDescription)
            return
        }
        //simpler solutions instead of timer solution, using boxbinding
        
    }
    
// Load some data from the Setting plist
    func loadPlist(){
        if let path = Bundle.main.path(forResource: "Setting", ofType: "plist") {
            if let dic = NSDictionary(contentsOfFile: path) as? [String : Any] {
                self.userDev = dic["ClientID"] as? String
                self.passDev = dic["ClientPass"] as? String
                self.reqConfigUrl = URL(string: (dic["ConfigURL"] as? String)!)
            }
        }
    }
    
    func checkDownload(downloaded : Bool?) {
        
        print("checkDownload LoginExtension : \(String(describing: downloaded))")
        
        self.removeLoadUI()
        
        if downloaded == nil {
            showAlertUILogin()
        } else if !downloaded!{
            loginUnsuccessful()
        }else {
            loginSuccessful()
        }
        
    }
    
    // A listener function to check if the fetching process of the config data successful or not
    func checkDownloadConfig(downloaded : Bool?) {
        
        print("checkDownloadConfig LoginExtension : \(String(describing: downloaded))")
        DispatchQueue.main.async {
            if downloaded == nil {
                self.showAlertUI()
            } else if !downloaded!{
                //todo handle it differently for rejected request
                self.showAlertUI()
            }else {
                self.downloadFinished()
                //            self.tokenEnd = self.configmodel?.getTokenEndpoint()
            }
        }
        
        
    }
    
    func checkSessionKey() -> Bool {
        
        sessionKey = KeyChain.loadKeyPair(tagString: "sessionKey")
//        sessionKey!["public"] = KeyChain.loadKey(tagString: "sessionPublic")
//        sessionKey!["private"] = KeyChain.loadKey(tagString: "sessionPrivate")
        if sessionKey != nil  {
            print("Keys already existed")
            return true
        } else {
            return false
        }

    }
    
    func checkConfig(){
        
        configmodel = EduidConfigModel(serverUrl: self.reqConfigUrl! )
        configmodel?.deleteAll()
        showLoadUI()
        configmodel?.downloadedSuccess.bind {
            self.checkDownloadConfig(downloaded: $0)
        }
        
        if configmodel?.getTokenEndpoint() != nil {
            self.tokenEnd = configmodel?.getTokenEndpoint()
            return
        }
        
        configmodel?.fetchServer()
        
        /*
        var timeoutCounter = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timerTmp in
            timeoutCounter += 1
            print(timeoutCounter)
            if (self.configmodel?.downloadedSuccess.value)!  {
                timerTmp.invalidate()
                self.downloadFinished()
                self.tokenEnd = self.configmodel?.getTokenEndpoint()
            } else if timeoutCounter == 3 {
                self.showAlertUI()
                timerTmp.invalidate()
            }
        }
        timer.fire()
        */
    }
    
    func downloadFinished () {
        self.removeLoadUI()
        self.tokenEnd = self.configmodel?.getTokenEndpoint()
        tokenModel = TokenModel(tokenURI: self.tokenEnd!)
        
        if (tokenModel?.fetchDatabase())! {
            self.loginSuccessful()
            return
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier != "toProfileExtension"{
            return
        }
        
        let destinationVC = segue.destination as! ServiceViewController
        autoreleasepool{
            destinationVC.exContext = self.extensionContext
            destinationVC.apString = self.configmodel?.getIssuer()
        }
    }
    
    func loginSuccessful(){
        self.tokenModel?.downloadSuccess.listener = nil
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toProfileExtension", sender: self)
        }
    }
    
    func loginUnsuccessful(){
        let rejectedTitle = NSLocalizedString("LoginRejectedTitle", comment: "Login rejected")
        let rejectedMsg = NSLocalizedString("LoginRejectedMessage", comment: "Login rejected message")
        let tryagainTxt = NSLocalizedString("TryAgain", comment: "try again text")
        
        let alert = UIAlertController(title: rejectedTitle, message: rejectedMsg, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: tryagainTxt, style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func showAlertUI(){
        let alertmessage = NSLocalizedString("TimeoutMessage", comment: "Message appears on the connection timeout")
        let tryagainText = NSLocalizedString("TryAgain", comment: "Try again text")
        let closeText = NSLocalizedString("Close", comment: "Close text")
        
        let alert = UIAlertController(title: "Timeout", message: alertmessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: tryagainText, style: .cancel, handler: {
            (alertAction) in
            self.checkConfig()
        }))
        alert.addAction(UIAlertAction(title: closeText, style: .default, handler: { (alertAction) in
            UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
        }))
        
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func showAlertUILogin(){
        let alertmessage = NSLocalizedString("TimeoutMessage", comment: "Message appears on the connection timeout")
        let tryagainText = NSLocalizedString("TryAgain", comment: "Try again text")
        let closeText = NSLocalizedString("Close", comment: "Close text")
        
        let alert = UIAlertController(title: "Timeout", message: alertmessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: tryagainText, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: closeText, style: .default, handler: { (alertAction) in
            UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
        }))
        
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func showLoadUI(){
        let tmpFrame = self.view.frame
        let view = UIView(frame: tmpFrame)
        view.tag = 1
        view.backgroundColor = UIColor.gray.withAlphaComponent(0.8)
        
        indicator.startAnimating()
        view.addSubview(indicator)
        self.view.addSubview(view)
    }
    
    func removeLoadUI(){
        indicator.stopAnimating()
        let view  = self.view.viewWithTag(1)
        view?.removeFromSuperview()
    }
    
    @IBAction func gestureDidSwipeDown(_ sender: UISwipeGestureRecognizer) {
        
        if self.usernameTF.isFirstResponder || self.passwordTF.isFirstResponder {
            self.view.endEditing(true)
        }
        
    }
    
}

extension ExtensionLoginViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return self.view.endEditing(true)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.autocorrectionType = .no
        
        if textField == self.passwordTF {
            textField.isSecureTextEntry = true
            if textField.text == NSLocalizedString("Password", comment: "") {
                textField.text = ""
            }
        } else {
            
            if textField.text == NSLocalizedString("Username", comment: "") {
                textField.text = ""
            }
        }
    }
    
}
