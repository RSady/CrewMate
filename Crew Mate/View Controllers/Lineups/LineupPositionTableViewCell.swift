//
//  LineupPositionTableViewCell.swift
//  Crew Mate
//
//  Created by Ryan Sady on 8/12/18.
//  Copyright © 2018 Ryan Sady. All rights reserved.
//

import UIKit

class LineupPositionTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var portImage: UIImageView!
    @IBOutlet weak var starboardImage: UIImageView!
    
    var member: CrewMember! {
        didSet{
            nameLabel.text = "\(member.firstName ?? "") \(member.lastName ?? "")"
            switch member.side {
            case "Port":
                portImage.image = UIImage(named: "oar")
                starboardImage.image = nil
            case "Starboard":
                starboardImage.image = UIImage(named: "oar")
                portImage.image = nil
            case "All":
                starboardImage.image = UIImage(named: "oar")
                portImage.image = UIImage(named: "oar")
            default:
                starboardImage.image = nil
                portImage.image = nil
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        
    }

}
