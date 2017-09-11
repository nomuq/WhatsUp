//
//  ContactsManager.swift
//  QuickChat
//
//  Created by ios3 on 09/09/17.
//  Copyright © 2017 Mexonis. All rights reserved.
//

import UIKit
import Contacts

class ContactsManager: NSObject {

    // PRAGMA MARK: - Contacts Authorization -
    /// Requests access to the user's contacts
    /// - parameter requestGranted: Set granted to true if the user allows access.
    class func requestAccess(_ requestGranted: @escaping (Bool) -> Void) {
        CNContactStore().requestAccess(for: .contacts) { (grandted, error) in
            requestGranted(grandted)
        }
    }
    
    /// Returns the current authorization status to access the contact data.
    /// - parameter requestStatus: The authorization the user has given the application to access an entity type.
    class func authorizationStatus(_ requestStatus: @escaping (CNAuthorizationStatus) -> Void) {
        requestStatus(CNContactStore.authorizationStatus(for: .contacts))
    }
    
    
    
    
    /// Fetching Contacts from phone
    /// - parameter completionHandler: Returns Either [CNContact] or Error.
    class func fetchContactsOnBackgroundThread( completionHandler : @escaping (Error?, [CNContact]) -> Swift.Void){
        
        DispatchQueue.global(qos: .userInitiated).async(execute: { () -> Void in
            let fetchRequest : CNContactFetchRequest = CNContactFetchRequest(keysToFetch:[CNContactVCardSerialization.descriptorForRequiredKeys()])
            var contacts = [CNContact]()
            CNContact.localizedString(forKey: CNLabelPhoneNumberiPhone)
            if #available(iOS 10.0, *) {
                fetchRequest.mutableObjects = false
            } else {
                // Fallback on earlier versions
            }
            fetchRequest.unifyResults = true
            fetchRequest.sortOrder = .userDefault
            do {
                try CNContactStore().enumerateContacts(with: fetchRequest) { (contact, stop) -> Void in
                    contacts.append(contact)
                }
                DispatchQueue.main.async(execute: { () -> Void in
                    completionHandler(nil, contacts)
                })
            } catch let error as NSError {
                completionHandler(error, contacts)
            }
            
        })
        
    }
    
    /// Convert CNPhoneNumber To digits
    /// - parameter CNPhoneNumber: Phone number.
    class func CNPhoneNumberToString(CNPhoneNumber : CNPhoneNumber) -> String{
        if let result: String = CNPhoneNumber.value(forKey: "digits") as? String{
            return result
        }
        return ""
    }
    

}
