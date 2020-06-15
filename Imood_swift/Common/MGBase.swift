//
//  MGBase.swift
//  Imood_swift
//
//  Created by Mac on 2020/6/15.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation
import UIKit

//项目基础配置
class MGBase{
    //视频分辨率
    public static var videoSize: CGSize{
        return CGSize(width: 1280, height: 1280)
    }
    //图片合成视频
    public static var photoMov: String{
        return "photo.mov"
    }
}
