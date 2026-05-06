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
    // MARK: - Theme
    static let backColor = UIColor(red: 23/255, green: 31/255, blue: 48/255, alpha: 1.0)
    static let themeBackground = UIColor(red: 12/255, green: 16/255, blue: 28/255, alpha: 1.0)
    static let themePanel = UIColor(red: 24/255, green: 34/255, blue: 52/255, alpha: 1.0)
    static let themePanelAlt = UIColor(red: 31/255, green: 44/255, blue: 66/255, alpha: 1.0)
    static let themeAccent = UIColor(red: 80/255, green: 232/255, blue: 209/255, alpha: 1.0)
    static let themeAccentWarm = UIColor(red: 255/255, green: 110/255, blue: 122/255, alpha: 1.0)
    static let themeTextPrimary = UIColor(red: 240/255, green: 245/255, blue: 255/255, alpha: 1.0)
    static let themeTextSecondary = UIColor(red: 164/255, green: 177/255, blue: 209/255, alpha: 1.0)
    //沙盒PATH
    static func videoPathWith(name: String) -> String {
        return NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true).first! + "/" + name
    }

}
