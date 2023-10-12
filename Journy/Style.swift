//
//  Style.swift
//  Journy
//
//  Created by Dylan Elliott on 12/10/2023.
//

import SwiftUI

extension SwiftUI.Font {
    static func youngSerif(size: CGFloat) -> SwiftUI.Font {
        return .custom("YoungSerif-Regular", size: size)
    }
}

extension UIFont {
    static func youngSerif(size: CGFloat) -> UIFont {
        return .init(name: "YoungSerif-Regular", size: size)!
    }
}
