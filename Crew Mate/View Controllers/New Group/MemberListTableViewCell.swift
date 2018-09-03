//
//  MemberListTableViewCell.swift
//  Crew Mate
//
//  Created by Ryan Sady on 9/2/18.
//  Copyright © 2018 Ryan Sady. All rights reserved.
//

import UIKit

class MemberListTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var picture: UIImageView!
    @IBOutlet weak var sideLabel: UILabel!
    
    var crewMember: CrewMember! {
        didSet {
            //Convert Image Data to UIImage
            if let imageData = crewMember.picture as Data? {
                let newImage = UIImage(data: imageData as Data)
                picture.image = newImage
            } else {
                picture.image = UIImage(named: "noUserImage")
            }
            
            nameLabel.text = "\(crewMember.firstName ?? "Error") \(crewMember.lastName ?? "Error")"
            sideLabel.text = crewMember.side
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        styleImageView(picture)
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }
    
    fileprivate func styleImageView(_ imageView: UIImageView) {
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = imageView.bounds.height / 2
        imageView.layer.borderColor = UIColor.black.cgColor
        imageView.layer.borderWidth = 1
        imageView.layer.masksToBounds = true
    }

}
