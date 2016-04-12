//
//  CourirUINodes.swift
//  Courir
//
//  Created by Sebastian Quek on 12/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import SpriteKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        self.init(red: CGFloat(red)/255,
                  green: CGFloat(green)/255,
                  blue: CGFloat(blue)/255,
                  alpha: 1.0)
    }
}

class CourirUINodes {
    static let buttonLetterSpace: CGFloat = 5
    
    static func generateAttributedString(text: String, _ color: UIColor) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text,
                                                         attributes: [NSForegroundColorAttributeName : color])
        attributedString.addAttribute(NSKernAttributeName,
                                      value: buttonLetterSpace,
                                      range: NSRange(location: 0, length: text.characters.count))
        return attributedString
    }
}