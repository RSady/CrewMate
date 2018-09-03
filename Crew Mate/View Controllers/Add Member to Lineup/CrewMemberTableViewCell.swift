//
//  CrewMemberTableViewCell.swift
//  Crew Mate
//
//  Created by Ryan Sady on 8/12/18.
//  Copyright © 2018 Ryan Sady. All rights reserved.
//

import UIKit

class CrewMemberTableViewCell: UITableViewCell {

    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var picture: UIImageView!
    
    var member: CrewMember! {
        didSet {
            nameLabel.textColor = .black
            nameLabel.text = "\(member.firstName ?? "Error") \(member.lastName ?? "Error")"
            picture.layer.cornerRadius = picture.frame.height / 2
            picture.layer.borderColor = UIColor.black.cgColor
            picture.layer.borderWidth = 1
            picture.layer.masksToBounds = true
            picture.clipsToBounds = true
            
            //Get Image Data and Convert to UIImage
            if let imageData = member.picture as NSData? {
                let newImage = UIImage(data: imageData as Data)
                picture.image = newImage
            } else {
                picture.image = UIImage(named: "noUserImage")
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            nameLabel.textColor = .white
            backgroundColor = aquaBlue
            layer.cornerRadius = bounds.height / 2
        } else {
            backgroundColor = .clear
            nameLabel.textColor = .black
        }
        
    }

}
