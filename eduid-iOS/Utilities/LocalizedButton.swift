//
//  LocalizedButton.swift
//  eduid-iOS
//
//  Created by Blended Learning Center on 31.10.18.
//  Copyright © 2018 Blended Learning Center. All rights reserved.
//
import UIKit
//Localized Button a helper class to help the language support of UI Button
class LocalizedButton : UIButton {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        guard let title = self.title(for: .normal) else { return }
        self.setTitle(NSLocalizedString(title, comment: "Localized Button"), for: .normal)
    }
}
