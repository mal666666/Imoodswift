//
//  MGDevice.swift
//  Imood_swift
//
//  Created by Mac on 2020/6/15.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation
import UIKit

class MGDevice {
    public class var screenWidth: CGFloat{
        get{
            return UIScreen.main.bounds.size.width
        }
    }
    public class var screenHeight: CGFloat{
        get{
            return UIScreen.main.bounds.size.height
        }
    }
}
