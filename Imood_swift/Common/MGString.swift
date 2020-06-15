//
//  MGString.swift
//  Imood_swift
//
//  Created by Mac on 2020/6/15.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation

//时分秒
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
