//
//  MGBase.swift
//  Imood_swift
//
//  Created by Mac on 2020/5/28.
//  Copyright © 2020 Mac. All rights reserved.
//

import UIKit

class MGBase {
    
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

extension URL{
    static func bundlePathWith(resouce: String ,type: String) -> URL {
        return URL.init(fileURLWithPath: Bundle.main.path(forResource: resouce, ofType: type)!)
    }
    static func domainPathWith(path: String) -> URL {
        return URL.init(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true).first! + "/" + path)
    }
}

extension String{
    static func customTimeWithSecond(sec: Float) -> String{
        guard sec > 0 else {
            return "00:00"
        }
        let h = Int(sec/3600)
        let m = Int(sec.truncatingRemainder(dividingBy: 3600)/60)
        let s = Int(sec.truncatingRemainder(dividingBy: 60))
        if h>0 {
            return String.init(format: "%.2d:%.2d:%.2d",h,m,s)
        }
        return String.init(format: "%.2d:%.2d",m,s)
    }
}
