//
//  MGBase.swift
//  Imood_swift
//
//  Created by Mac on 2020/6/15.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

//项目基础配置
class MGBase{
    //视频分辨率
    public static var videoSize: CGSize{
        return CGSize(width: 1280, height: 1280)
    }
    //图片合成视频名字
    public static var photoMov: String{
        return "photo.mov"
    }
    //合成音乐名字
    public static var audioName: String{
        return "audio.m4a"
    }
    //音视频合成名字
    public static var videoName: String{
        return "video.mov"
    }
    //录音名字
    public static var recoderName: String{
        return "recoder.m4a"
    }
    //录音开始时间
    static var recoderStartTime: CMTime = .zero

}
