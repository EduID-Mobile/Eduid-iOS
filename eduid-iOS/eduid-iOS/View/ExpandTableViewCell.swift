//
//  ExpandTableViewCell.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 12.01.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//

import UIKit

class ExpandTableViewCell: UITableViewCell {

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
