//
//  Composition.swift
//  Imood_swift
//
//  Created by Mac on 2020/6/3.
//  Copyright © 2020 Mac. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class Composition: NSObject {
    //音乐合成沙河路经
    let exportMusicPath = "exportMusic.m4a"
    //音频合成，传入音频Url数组
    func compositionWithArr(audioUrlArr: [URL], completion: @escaping (_ string: URL?) -> Void){
        let mixComposition = AVMutableComposition()
        for audioUrl in audioUrlArr {
            if audioUrl.path  == "/" {
                continue
            }
            let audioAsset = AVURLAsset.init(url: audioUrl )
            let compositionCommentaryTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid)
            audioAsset.tracks(withMediaType: .audio)
            do {
                try compositionCommentaryTrack?.insertTimeRange(CMTimeRange.init(start: .zero, duration: audioAsset.duration), of: audioAsset.tracks(withMediaType: .audio).first!, at: CMTime.init(seconds: 0, preferredTimescale: 1))
            } catch {
                print("合成失败")
            }
        }
        let assetExport = AVAssetExportSession.init(asset: mixComposition, presetName: AVAssetExportPresetAppleM4A)
        assetExport?.outputFileType = .m4a
        let url = URL.domainPathWith(path: exportMusicPath)
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print(url.path + "删除失败")
            }
        }
        assetExport?.outputURL = url
        assetExport?.shouldOptimizeForNetworkUse = true
        assetExport?.exportAsynchronously(completionHandler: {
            print("混合音乐完成: \(assetExport?.outputURL! as Any)")
            completion(url)
        })
    }
    //CGImage->CVPixelBuffer
    func pixelBuffer(from image: CGImage?, size: CGSize) -> CVPixelBuffer? {
        let options : [NSObject:AnyObject] = [
            kCVPixelBufferCGImageCompatibilityKey : true as AnyObject,
            kCVPixelBufferCGBitmapContextCompatibilityKey : true as AnyObject
        ]
        
        var pxbuffer: CVPixelBuffer? = nil
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, options as CFDictionary, &pxbuffer)

        assert(status == kCVReturnSuccess && pxbuffer != nil, "Invalid parameter not satisfying: status == kCVReturnSuccess && pxbuffer != nil")
        
        if let pxbuffer = pxbuffer {
            CVPixelBufferLockBaseAddress(pxbuffer, CVPixelBufferLockFlags(rawValue: 0))
        }
        let pxdata :UnsafeMutableRawPointer = CVPixelBufferGetBaseAddress(pxbuffer!)!
        //assert(pxdata != nil, "Invalid parameter not satisfying: pxdata != nil")
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pxdata, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 4 * Int(size.width), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        //assert(context != nil, "Invalid parameter not satisfying: context != nil")
        context?.draw(image!, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(image!.width), height: CGFloat(image!.height)))
        if let pxbuffer = pxbuffer {
            CVPixelBufferUnlockBaseAddress(pxbuffer, CVPixelBufferLockFlags(rawValue: 0))
        }
        
        return pxbuffer
    }
    
}
