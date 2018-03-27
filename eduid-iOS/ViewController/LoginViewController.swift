//
//  ViewController.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 28.11.17.
//  Copyright © 2017 Blended Learning Center. All rights reserved.
//

import UIKit
import JWTswift
import TextFieldEffects
import NVActivityIndicatorView

/**
 The login view controller, where the user could insert her/his login data.
 This view controller mostly working with the TokenModel for its main function
 
 ## Functions :
 - The view, where the main login process happened
 - Handling the response from the authentication server, if success => perform a segue
 
 */

class LoginViewController: UIViewController {
    
    private var configModel = EduidConfigModel()
    //    private var requestData = RequestData()
    
    @IBOutlet weak var usernameTF: IsaoTextField! //    UITextField!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var backgroundView: UIImageView!
    @IBOutlet weak var passwordTF: IsaoTextField! //UITextField!
    @IBOutlet weak var loginButton: UIButton!
    private var indicator : NVActivityIndicatorView!
    
    private var userDev: String?
    private var passDev: String?
    private var tokenEnd : URL?
    private var sessionKey : [String : Key]?
    private var signingKey : Key?
    var tokenModel : TokenModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadPlist()
        tokenEnd = configModel.getTokenEndpoint()
        print("Issuer = \(String(describing: configModel.getIssuer()))")
        print("TOKEN ENDPOINT = \(tokenEnd?.absoluteString ?? "error")" )
        
        self.tokenModel = TokenModel(tokenURI: self.tokenEnd!)
        
        let keystore = KeyStore()
        
        if !self.loadKey() {
            sessionKey = KeyStore.generateKeyPair(keyType: kSecAttrKeyTypeRSA as String)!
            self.saveKey()
        }
        
        var urlPathKey = Bundle.main.url(forResource: "ios_priv", withExtension: "jwks")
        let keyID = keystore.getPrivateKeyIDFromJWKSinBundle(resourcePath: (urlPathKey?.relativePath)!)
        urlPathKey = Bundle.main.url(forResource: "ios_priv", withExtension: "pem")
        
        guard let privateKeyID = keystore.getPrivateKeyFromPemInBundle(resourcePath: (urlPathKey?.relativePath)!, identifier: keyID!) else {
            print("ERROR getting private key")
            return
        }
        //key object always save the kid in base64url
        signingKey = keystore.getKey(withKid: privateKeyID)!
        
        setUIelements()
        
        //        tokenModel = TokenModel(tokenURI: self.tokenEnd!)
        //        if (tokenModel?.fetchDatabase())! {
        //            self.loginSuccessful()
        //            return
        //        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if self.view.isHidden {
            self.view.isHidden = false
        }
    }
    
    override func viewWillLayoutSubviews() {
        imageView.layer.cornerRadius = imageView.layer.bounds.height / 2
        imageView.clipsToBounds = true
    }
    
    /**
     Setting the UI elements for the user login process
     */
    func setUIelements(){
        
        //backgroundView.loadGif(name: "testGif")
        
        //Set the observer for the keyboard events, so that the keyboard wouldn't cover the text fields
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
        
        let image = UIImage(named: "appicon400.png")
        imageView.image = image
        
        usernameTF.inactiveColor = UIColor.gray
        passwordTF.inactiveColor = UIColor.gray
        usernameTF.activeColor = UIColor(red: 85/255, green: 146/255, blue: 193/255, alpha: 1.0)
        passwordTF.activeColor = UIColor(red: 85/255, green: 146/255, blue: 193/255, alpha: 1.0) //UIColor.red
       
        
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
    
    /** Move the view 150 to the top so the keyboard won't cover any important UI components
     */
    @objc func keyboardWillShow(){
        self.view.frame.origin.y = -150 //move upward 150
    }
    
    /** Move the view back to its original place, after keyboard is not longer used
     */
    @objc func keyboardWillHide(){
        self.view.frame.origin.y = 0
    }
    
    /**
     Listener function to the download status of the TokenModel Controller
     */
    func checkDownload(downloaded : Bool?) {
        print("checkDownload LoginVC : \(String(describing: downloaded))")
        
        self.removeLoadUI()
        
        if downloaded == nil {
            showAlertUI()
        }else if !downloaded! {
            loginUnsuccessful()
        }else {
            loginSuccessful()
        }
        
    }
    
    /**
     Load app credentials, which is required to communicate with the AP(ex. edu-ID service)
     */
    func loadPlist(){
        if let path = Bundle.main.path(forResource: "Setting", ofType: "plist") {
            if let dic = NSDictionary(contentsOfFile: path) as? [String : Any] {
                self.userDev = dic["ClientID"] as? String
                self.passDev = dic["ClientPass"] as? String
            }
        }
    }
    
    /**
     Check if session keys are already created before, if yes, the user wouldn't be required to login anymore
    */
    func loadKey() -> Bool {
        sessionKey = [String : Key]()
        sessionKey = KeyChain.loadKeyPair(tagString: "sessionKey")
        
        if  sessionKey != nil {
            
            print("Keys already existed")
            return true
            
        } else {
            return false
        }
    }
    
    /**
     Save a new generated session key pair, which is created after user log in
    */
    func saveKey() {
        let a = KeyChain.saveKeyPair(tagString: "sessionKey", keyPair: sessionKey!)
        
        print("SAVE KEY : \(a)")
    }
    
    @IBAction func login(_ sender: Any) {
        
        guard let userSub : String = usernameTF.text , let pass : String  = passwordTF.text else{
            return
        }
        showLoadUI()
        
        // Bind the boolean var into a listener, so this VC know exactly the current status of the login process.
        tokenModel?.downloadSuccess.bind (listener: { (dlBool) in
            DispatchQueue.main.async {
                self.checkDownload(downloaded: dlBool)
            }
        })
        
        let userAssert = tokenModel?.createUserAssert(userSub: userSub , password: pass, issuer: userDev! , audience: configModel.getIssuer()!, keyToSend: sessionKey!["public"]!, keyToSign: signingKey!) //use signing key
        do{
            try tokenModel?.fetchServer(username: userDev!, password: passDev!, assertionBody: userAssert!)
        } catch {
            print(error.localizedDescription)
            return
        }
        
        /* BASIC APPROACH WITHOUT LISTENER, USING TIMER MANUALLY
         var timeoutCounter : Double = 0
         let timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timerTmp in
         timeoutCounter += timerTmp.timeInterval
         if self.tokenModel?.tokenDownloaded != nil {
         
         if (self.tokenModel?.tokenDownloaded)! {
         print("GOT TOKEN")
         timerTmp.invalidate()
         self.loginSuccessful()
         self.removeLoadUI()
         
         }else {
         print("Login Rejected")
         timerTmp.invalidate()
         self.loginUnsuccessful()
         self.removeLoadUI()
         }
         }
         else if timeoutCounter == 5 {
         self.showAlertUI()
         timerTmp.invalidate()
         self.removeLoadUI()
         }
         }
         timer.fire()
         */
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier  != "toProfileList" {
            return
        }
        guard let profileListVC = segue.destination as? ProfileListViewController else {return}
        profileListVC.token = self.tokenModel
    }
    
    func loginSuccessful(){ 
        self.tokenModel?.downloadSuccess.listener = nil
        DispatchQueue.main.async {
            self.performSegue(withIdentifier: "toProfileList", sender: self)
        }
        
    }
    
    func loginUnsuccessful(){
        
        let alert = UIAlertController(title: "Login rejected", message: "Please check your login or username again", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    func showAlertUI(){
        
        let alert = UIAlertController(title: "Timeout: no connection to the server", message: "Please check your internet connection", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Close App", style: .default, handler: { (alertAction) in
            UIControl().sendAction(#selector(NSXPCConnection.suspend), to: UIApplication.shared, for: nil)
        }))
        alert.addAction(UIAlertAction(title: "Try Again", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func showLoadUI(){
        let tmpFrame = self.view.window?.frame
        let view = UIView(frame: tmpFrame!)
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
    
    /** Remove the keyboard from the view with a swipe down gesture
     */
    @IBAction func gestureDidSwipeDown(_ sender: UISwipeGestureRecognizer) {
        
        if self.usernameTF.isFirstResponder || self.passwordTF.isFirstResponder {
            self.view.endEditing(true)
        }
    }
    
}

extension LoginViewController : UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return self.view.endEditing(true)
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.autocorrectionType = .no
        
        if textField == self.passwordTF {
            textField.isSecureTextEntry = true
            if textField.text == "Password"{
                textField.text = ""
            }
        } else {
            
            if textField.text == "Username" {
                textField.text = ""
            }
            
        }
    }
    
}
