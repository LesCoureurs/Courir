//
//  UIKitExtensions.swift
//  Courir
//
//  Created by Sebastian Quek on 12/4/16.
//  Copyright © 2016 NUS CS3217. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
        self.init(red: CGFloat(red)/255,
                  green: CGFloat(green)/255,
                  blue: CGFloat(blue)/255,
                  alpha: 1.0)
    }
}

extension UIButton {
    private func generateAttributedString(text: String,
                                          _ letterSpacing: CGFloat,
                                          _ color: UIColor) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: text,
                                                         attributes: [NSForegroundColorAttributeName : color])
        attributedString.addAttribute(NSKernAttributeName,
                                      value: letterSpacing,
                                      range: NSRange(location: 0, length: text.characters.count))
        return attributedString
    }
    
    func setLetterSpacing(letterSpacing: CGFloat) {
        let title = currentTitle!
        let color = currentTitleColor
        let highlightedColor = color.colorWithAlphaComponent(0.4)
        let disabledColor = color.colorWithAlphaComponent(0.2)
        
        setAttributedTitle(generateAttributedString(title, letterSpacing, color),
                           forState: .Normal)
        setAttributedTitle(generateAttributedString(title, letterSpacing, highlightedColor),
                           forState: .Highlighted)
        setAttributedTitle(generateAttributedString(title, letterSpacing, disabledColor),
                           forState: .Disabled)
    }

    func setFadeForUserActions() {
        let color = currentTitleColor
        let highlightedColor = color.colorWithAlphaComponent(0.4)
        let disabledColor = color.colorWithAlphaComponent(0.2)
        setTitleColor(highlightedColor, forState: .Highlighted)
        setTitleColor(disabledColor, forState: .Disabled)
    }
}