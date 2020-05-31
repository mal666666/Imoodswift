//
//  MGBase.swift
//  Imood_swift
//
//  Created by Mac on 2020/5/28.
//  Copyright © 2020 Mac. All rights reserved.
//

import UIKit

class MGBase: NSObject {

    public class func screen_width() -> CGFloat {
        return UIScreen.main.bounds.size.width
    }
    public class func screen_height() -> CGFloat {
        return UIScreen.main.bounds.size.height
    }

}
