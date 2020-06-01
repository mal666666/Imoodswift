//
//  MGBase.swift
//  Imood_swift
//
//  Created by Mac on 2020/5/28.
//  Copyright © 2020 Mac. All rights reserved.
//

import UIKit

class MGBase: NSObject {
    
    //private(set) var name : String!
    
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
