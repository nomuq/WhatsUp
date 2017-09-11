//  MIT License

//  Copyright (c) 2017 Satish Babariya

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import Foundation
import UIKit
import Contacts
import Firebase

class User: NSObject {
    
    //MARK: Properties
    let name: String
    let number: String
    let id: String
    var profilePic: UIImage
    
    //MARK: Methods
    class func registerUser(withName: String, number: String, profilePic: UIImage, completion: @escaping (Bool) -> Swift.Void) {
        
                let storageRef = Storage.storage().reference().child("usersProfilePics").child((Auth.auth().currentUser?.uid)!)
                let imageData = UIImageJPEGRepresentation(profilePic, 0.1)
                storageRef.putData(imageData!, metadata: nil, completion: { (metadata, err) in
                    if err == nil {
                        let path = metadata?.downloadURL()?.absoluteString
                        let values = ["name": withName, "number": number, "profilePicLink": path!]
                        Database.database().reference().child("users").child((Auth.auth().currentUser?.uid)!).child("credentials").updateChildValues(values, withCompletionBlock: { (errr, _) in
                            if errr == nil {
                                let values = ["id": (Auth.auth().currentUser?.uid)!,"createdAt": NSDate().timeIntervalSince1970] as [String : Any]
                                Database.database().reference().child("list").child(number).updateChildValues(values, withCompletionBlock: { (errr, _) in
                                    if errr == nil {
                                        completion(true)
                                    }
                                })
                            }
                        })
                    }
                })
        
            
    }
    

    class func logOutUser(completion: @escaping (Bool) -> Swift.Void) {
        do {
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "authVerificationID")
            if UIApplication.shared.isRegisteredForRemoteNotifications{
                UIApplication.shared.unregisterForRemoteNotifications()
            }
            Messaging.messaging().shouldEstablishDirectChannel = false
            completion(true)
        } catch _ {
            completion(false)
        }
    }
    

    class func loginUser(verificationID: String, verificationCode: String, completion: @escaping (Bool) -> Swift.Void) {
        let credential = PhoneAuthProvider.provider().credential(
            withVerificationID: verificationID,
            verificationCode: verificationCode)
        Auth.auth().signIn(with: credential) { (user, error) in
            if error == nil {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    

    
   class func info(forUserID: String, completion: @escaping (User) -> Swift.Void) {
        Database.database().reference().child("users").child(forUserID).child("credentials").observeSingleEvent(of: .value, with: { (snapshot) in
            if let data = snapshot.value as? [String: String] {
                let name = data["name"]!
                let email = data["number"]!
                let link = URL.init(string: data["profilePicLink"]!)
                URLSession.shared.dataTask(with: link!, completionHandler: { (data, response, error) in
                    if error == nil {
                        let profilePic = UIImage.init(data: data!)
                        let user = User.init(name: name, number: email, id: forUserID, profilePic: profilePic!)
                        completion(user)
                    }
                }).resume()
            }
        })
    }
    
    class func search(forPhoneNumber: String, completion: @escaping (User) -> Swift.Void) {
        Database.database().reference().child("list").child(forPhoneNumber).observeSingleEvent(of: .value, with: { (snapshot) in
            if let data = snapshot.value as? [String: Any] {
                let id = data["id"]!
                Database.database().reference().child("users").child(id as! String).child("credentials").observeSingleEvent(of: .value, with: { (snapshot) in
                    if let data = snapshot.value as? [String: String] {
                        let name = data["name"]!
                        let email = data["number"]!
                        let link = URL.init(string: data["profilePicLink"]!)
                        URLSession.shared.dataTask(with: link!, completionHandler: { (data, response, error) in
                            if error == nil {
                                let profilePic = UIImage.init(data: data!)
                                let user = User.init(name: name, number: email, id: id as! String, profilePic: profilePic!)
                                completion(user)
                            }
                        }).resume()
                    }
                })
            }
        })
    }
       
    
    class func isOnline(){
         Database.database().reference().child("list").child((Auth.auth().currentUser?.phoneNumber)!).child("status").setValue(true)
    }
    
    class func isOffline(){
         Database.database().reference().child("list").child((Auth.auth().currentUser?.phoneNumber)!).child("status").setValue(false)
    }
    
    class func observeUserStatus(number: String, completion: @escaping (Bool) -> Swift.Void) {
        Database.database().reference().child("list").child(number).child("status").queryOrderedByValue().queryEqual(toValue: true).observe(.value) { (data: DataSnapshot) in
            completion(true)
        }
        Database.database().reference().child("list").child(number).child("status").queryOrderedByValue().queryEqual(toValue: false).observe(.value) { (data: DataSnapshot) in
            completion(false)
        }
    }
    
    
    //MARK: Inits
    init(name: String, number: String, id: String, profilePic: UIImage) {
        self.name = name
        self.number = number
        self.id = id
        self.profilePic = profilePic
    }
}

