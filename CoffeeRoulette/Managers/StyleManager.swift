//
//  StyleManager.swift
//  CoffeeRoulette
//
//  Created by Erik Goossens on 2018-08-06.
//  Copyright © 2018 Will Chew. All rights reserved.
//

import Foundation
import ChameleonFramework

typealias Style = StyleManager

//MARK: - StyleManager
final class StyleManager {
    
    // MARK: - StyleManager
    
    static func setUpTheme() {
        Chameleon.setGlobalThemeUsingPrimaryColor(primaryTheme(), withSecondaryColor: theme(), usingFontName: font(), andContentStyle: content())
    }
    
    // MARK: - Theme
    
    static func primaryTheme() -> UIColor {
        return UIColor.black
    }
    
    static func theme() -> UIColor {
        return FlatWhite()
    }
    
    static func toolBarTheme() -> UIColor {
        return FlatMint()
    }
    
    static func tintTheme() -> UIColor {
        return FlatMint()
    }
    
    static func titleTextTheme() -> UIColor {
        return FlatWhite()
    }
    
    static func titleTheme() -> UIColor {
        return FlatCoffeeDark()
    }
    
    static func textTheme() -> UIColor {
        return FlatMint()
    }
    
    static func backgroudTheme() -> UIColor {
        return FlatMint()
    }
    
    static func positiveTheme() -> UIColor {
        return FlatMint()
    }
    
    static func negativeTheme() -> UIColor {
        return FlatMintDark()
    }
    
    static func clearTheme() -> UIColor {
        return UIColor.clear
    }
    
    // MARK: - Content
    
    static func content() -> UIContentStyle {
        return UIContentStyle.contrast
    }
    
    // MARK: - Font
    static func font() -> String {
        return UIFont(name: FontType.Primary.fontName, size: FontType.Primary.fontSize)!.fontName
    }
}

//MARK: - FontType
enum FontType {
    case Primary
}

extension FontType {
    var fontName: String {
        switch self {
        case .Primary:
            return "HelveticaNeue"
        }
    }
    
    var fontSize: CGFloat {
        switch self {
        case .Primary:
            return 16
        }
    }
    
    var fontColor: UIColor {
        switch self {
        case .Primary:
            return UIColor.flatWhite
        }
    }
}
