//
//  EquipmentTableViewCell.swift
//  Crew Mate
//
//  Created by Ryan Sady on 9/3/18.
//  Copyright © 2018 Ryan Sady. All rights reserved.
//

import UIKit

class EquipmentTableViewCell: UITableViewCell {

    @IBOutlet weak var picture: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var checkBox: UIImageView!
    
    var equipment: Equipment! {
        didSet {
            nameLabel.text = equipment.name ?? "Error"
            if let imageData = equipment.image as Data? {
                let newImage = UIImage(data: imageData as Data)
                picture.image = newImage
            } else {
                picture.image = UIImage(named: "noEquipmentImage")
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        picture.layer.cornerRadius = picture.bounds.height / 2
        picture.layer.borderColor = UIColor.black.cgColor
        picture.layer.borderWidth = 1
        picture.layer.masksToBounds = true
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        if selected {
            switch equipment.type?.lowercased() {
            case "boat":
                checkBox.image = UIImage(named: "boatIcon")
            case "oar":
                checkBox.image = UIImage(named: "oarIcon")
            default:
                checkBox.image = nil
            }
        } else {
            checkBox.image = nil
        }
        // Configure the view for the selected state
    }

}
