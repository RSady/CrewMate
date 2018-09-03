//
//  Extensions.swift
//  Crew Mate
//
//  Created by Ryan Sady on 8/11/18.
//  Copyright © 2018 Ryan Sady. All rights reserved.
//

import Foundation
import UIKit
import SwiftyJSON

let aquaBlue = UIColor(red:0.00, green:0.59, blue:1.00, alpha:1.0)
let disabledBlue = UIColor(red:0.55, green:0.81, blue:1.00, alpha:1.0)



extension UIPickerView {
    
    func setPickerLabels(labels: [Int:UILabel], containedView: UIView) { // [component number:label]
        
        let fontSize:CGFloat = 20
        let labelWidth:CGFloat = containedView.bounds.width / CGFloat(self.numberOfComponents)
        let x:CGFloat = self.frame.origin.x + 50
        let y:CGFloat = (self.frame.size.height / 2) - (fontSize / 2)
        
        for i in 0...self.numberOfComponents {
            
            if let label = labels[i] {
                
                if self.subviews.contains(label) {
                    label.removeFromSuperview()
                }
                
                label.frame = CGRect(x: x + labelWidth * CGFloat(i), y: y, width: labelWidth, height: fontSize)
                label.font = UIFont.boldSystemFont(ofSize: fontSize)
                label.backgroundColor = .clear
                label.textAlignment = NSTextAlignment.center
                
                self.addSubview(label)
            }
        }
    }
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func alertPopup(title: String, message: String, buttonTitle: String) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: buttonTitle, style: .default, handler:  nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func showError(message: String) {
        let alertController = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        self.present(alertController, animated: true, completion: nil)
    }
    
    func version() -> String {
        if let dict = Bundle.main.infoDictionary {
            if let version = dict["CFBundleShortVersionString"] as? String,
                let build = dict["CFBundleVersion"] as? String {
                return "\(version) Build \(build)"
            }
            return ""
        }
        return ""
    }
    
    
}

func createEquipmentJson(from equipment: Equipment?) -> JSON {
    if let equip = equipment {
        
        let image: String = {
            //Compare Current Image to Saved Image - If Image matches "noEquipmentImage" do not save (to reduce export file size)
            if let imageData = equip.image as Data? {
                if let newImage = UIImage(data: imageData as Data) {
                    if !(newImage.isEqual(UIImage(named: "noEquipmentImage"))) {
                        return convertImageToBase64(image: newImage)
                    }
                }
            }
            return ""
        }()
        
        return [equip.type! : [ "id" : equip.id ?? "",
                                "image" : image,
                                "name" : equip.name ?? "",
                                "type" : equip.type ?? ""]
        ]
    } else {
        return [:]
    }
}

func getDataFileSize(from data: Data) {
    let byteCount = data.count
    let byteCountFormatter = ByteCountFormatter()
    byteCountFormatter.allowedUnits = [.useKB]
    byteCountFormatter.countStyle = .file
    let string = byteCountFormatter.string(fromByteCount: Int64(byteCount))
    print("File Size: \(string)")
}

func convertImageToBase64(image: UIImage) -> String {
    if let imageData = image.jpegData(compressionQuality: 0.7) {
        return imageData.base64EncodedString(options: Data.Base64EncodingOptions.lineLength64Characters)
    } else {
        return ""
    }
}

func convertBase64ToImage(imageString: String) -> UIImage {
    if let imageData = Data(base64Encoded: imageString, options: Data.Base64DecodingOptions.ignoreUnknownCharacters) {
        if let returnImage = UIImage(data: imageData) {
            return returnImage
        }
    } else {
        return UIImage(named: "userSilhoutte") ?? UIImage()
    }
    return UIImage()
}

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

func style(button: UIButton) {
    button.layer.cornerRadius = 10
    
}
