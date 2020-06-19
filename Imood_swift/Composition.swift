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
        URL.domainPathClear(url: url)

        assetExport?.outputURL = url
        assetExport?.shouldOptimizeForNetworkUse = true
        assetExport?.exportAsynchronously(completionHandler: {
            print("混合音乐完成: \(assetExport?.outputURL! as Any)")
            completion(url)
        })
    }
    //CGImage->CVPixelBuffer
    func pixelBuffer(from image: CGImage, size: CGSize) -> CVPixelBuffer? {
        let options : [NSObject:AnyObject] = [
            kCVPixelBufferCGImageCompatibilityKey : true as AnyObject,
            kCVPixelBufferCGBitmapContextCompatibilityKey : true as AnyObject
        ]
        
        var pxbuffer: CVPixelBuffer? = nil
        CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, options as CFDictionary, &pxbuffer)
        
        if let pxbuffer = pxbuffer {
            CVPixelBufferLockBaseAddress(pxbuffer, CVPixelBufferLockFlags(rawValue: 0))
        }
        let pxdata :UnsafeMutableRawPointer = CVPixelBufferGetBaseAddress(pxbuffer!)!
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: pxdata, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pxbuffer!), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        context?.draw(image, in: CGRect(x: 0, y: 0, width: Int(image.width), height: Int(image.height)))
        if let pxbuffer = pxbuffer {
            CVPixelBufferUnlockBaseAddress(pxbuffer, CVPixelBufferLockFlags(rawValue: 0))
        }
        
        return pxbuffer
    }
    //图片合成视频
    func writeImage(imgArr:Array<UIImage> ,moviePath:String ,size:CGSize ,duration:CGFloat ,fps:Int)  {
        unlink(moviePath)
        let url = URL.domainPathWith(path: moviePath)
        URL.domainPathClear(url: url)

        let videoWriter = try? AVAssetWriter.init(url: url, fileType: .mov)
        let videoSettingS = [AVVideoCodecKey:AVVideoCodecH264
            ,AVVideoWidthKey: size.width
            ,AVVideoHeightKey: size.height] as [String : Any]
        let videoWriterInput = AVAssetWriterInput.init(mediaType: .video, outputSettings: videoSettingS)
        let soucePixelBufferAttributesDic = [kCVPixelBufferPixelFormatTypeKey:kCVPixelFormatType_32ARGB]as [String : Any]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor.init(assetWriterInput: videoWriterInput, sourcePixelBufferAttributes: soucePixelBufferAttributesDic)
        videoWriter?.add(videoWriterInput)
        videoWriter?.startWriting()
        videoWriter?.startSession(atSourceTime: .zero)
        let imageCount = imgArr.count
        let averageTime: CGFloat = duration/CGFloat(imageCount)
        var frame:Int = 0
        videoWriterInput.requestMediaDataWhenReady(on: DispatchQueue(label: "mediaInputQueue")) {
            while(videoWriterInput.isReadyForMoreMediaData){
                if frame >= imgArr.count {
                    videoWriterInput.markAsFinished()
                    videoWriter?.finishWriting(completionHandler: {
                    })
                    break
                }
                var buffer: CVPixelBuffer? = nil
                buffer = self.pixelBuffer(from: imgArr[frame].cgImage!, size: size)
                let ct = CMTime(seconds: Double(frame) * Double(averageTime), preferredTimescale: CMTimeScale(fps))
                CMTimeShow(ct)
                let state = adaptor.append(buffer!, withPresentationTime:ct)
                frame += 1
                if !state {print(state)}
            }
        }
    
    }
    
}
