//
//  UIView.swift
//  DataFlor
//
//  Created by Chandana Murthy on 19.05.22.
//

import Foundation
import UIKit

extension UIView {
    func hideViewWithAnimation(shouldHide: Bool) {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = shouldHide ? 0 : 1
        })
    }

    func addConstrained(subview: UIView) {
        addSubview(subview)
        subview.translatesAutoresizingMaskIntoConstraints = false
        subview.topAnchor.constraint(equalTo: topAnchor).isActive = true
        subview.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        subview.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        subview.bottomAnchor.constraint(equalTo: bottomAnchor).isActive = true
    }
}
