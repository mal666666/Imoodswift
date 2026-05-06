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
    private func minTime(_ lhs: CMTime, _ rhs: CMTime) -> CMTime {
        return CMTimeCompare(lhs, rhs) <= 0 ? lhs : rhs
    }
    
    //音频合成，传入音频Url数组
    func audioCompositionWithArr(audioUrlArr: [URL], completion: @escaping (_ string: URL?) -> Void){
        let mixComposition = AVMutableComposition()
        var hasValidAudioTrack = false
        
        for audioUrl in audioUrlArr {
            if audioUrl.path == "/" || URL.fileSize(url: audioUrl) == 0 {
                continue
            }
            
            let audioAsset = AVURLAsset(url: audioUrl)
            guard let sourceTrack = audioAsset.tracks(withMediaType: .audio).first else {
                continue
            }
            guard let mixTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) else {
                continue
            }
            
            do {
                try mixTrack.insertTimeRange(
                    CMTimeRange(start: .zero, duration: audioAsset.duration),
                    of: sourceTrack,
                    at: .zero
                )
                hasValidAudioTrack = true
            } catch {
                print("音轨插入失败: \(error.localizedDescription)")
            }
        }
        
        guard hasValidAudioTrack else {
            completion(nil)
            return
        }
        
        guard let assetExport = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetAppleM4A) else {
            completion(nil)
            return
        }
        
        assetExport.outputFileType = .m4a
        let url = URL.domainPathWith(name: MGBase.audioName)
        URL.domainPathClear(url: url)

        assetExport.outputURL = url
        assetExport.shouldOptimizeForNetworkUse = true
        assetExport.exportAsynchronously {
            DispatchQueue.main.async {
                if assetExport.status == .completed {
                    completion(url)
                } else {
                    print("混合音乐失败: \(assetExport.error?.localizedDescription ?? "unknown")")
                    completion(nil)
                }
            }
        }
    }
    
    //最终音视频合成
    func audioVideoComposition(videoTime:Int64, completion: @escaping(_ url: URL?) -> Void) {
        let audioUrl:URL    = URL.domainPathWith(name: MGBase.audioName)
        let photoMovUrl:URL = URL.domainPathWith(name: MGBase.photoMov)
        let videoUrl:URL    = URL.domainPathWith(name: MGBase.videoName)
        let recorderUrl:URL = URL.domainPathWith(name: MGBase.recoderName)

        URL.domainPathClear(url: videoUrl)
        
        let mixComposition:AVMutableComposition = AVMutableComposition()
        //视频采集
        guard URL.fileSize(url: photoMovUrl) != 0 else {
            completion(nil)
            return
        }
        
        let videoAsset:AVURLAsset = AVURLAsset.init(url: photoMovUrl)
        guard let sourceVideoTrack = videoAsset.tracks(withMediaType: .video).first,
              let videoTrack = mixComposition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
            completion(nil)
            return
        }
        
        let desiredDuration = CMTime(seconds: Double(videoTime), preferredTimescale: 600)
        let videoDuration = minTime(videoAsset.duration, desiredDuration)
        let videoTimeRange = CMTimeRange(start: .zero, duration: videoDuration)
        
        do {
            try videoTrack.insertTimeRange(videoTimeRange, of: sourceVideoTrack, at: .zero)
        } catch {
            print("视频轨道插入失败: \(error.localizedDescription)")
            completion(nil)
            return
        }
        
        //音频采集
        if URL.fileSize(url: audioUrl) != 0 {
            let audioAsset:AVURLAsset = AVURLAsset.init(url: audioUrl)
            if let sourceAudioTrack = audioAsset.tracks(withMediaType: .audio).first,
               let audioTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                let audioDuration = minTime(audioAsset.duration, videoDuration)
                let audioTimeRange = CMTimeRange(start: .zero, duration: audioDuration)
                do {
                    try audioTrack.insertTimeRange(audioTimeRange, of: sourceAudioTrack, at: .zero)
                } catch  {
                    print("音频无效: \(error.localizedDescription)")
                }
            }
        }
        
        //录音采集
        if URL.fileSize(url: recorderUrl) != 0 {
            let recorderAsset:AVURLAsset = AVURLAsset.init(url: recorderUrl)
            if let recorderSourceTrack = recorderAsset.tracks(withMediaType: .audio).first,
               let recorderTrack = mixComposition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid) {
                if CMTimeCompare(MGBase.recoderStartTime, videoDuration) < 0 {
                    let availableDuration = CMTimeSubtract(videoDuration, MGBase.recoderStartTime)
                    let recorderDuration = minTime(recorderAsset.duration, availableDuration)
                    let recorderTimeRange = CMTimeRange(start: .zero, duration: recorderDuration)
                    do {
                        try recorderTrack.insertTimeRange(recorderTimeRange, of: recorderSourceTrack, at: MGBase.recoderStartTime)
                    } catch  {
                        print("录音无效: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        //创建输出
        guard let assetExport = AVAssetExportSession(asset: mixComposition, presetName: AVAssetExportPresetMediumQuality) else {
            completion(nil)
            return
        }
        assetExport.outputFileType = .mov
        assetExport.outputURL = videoUrl
        assetExport.exportAsynchronously {
            DispatchQueue.main.async {
                if assetExport.status == .completed {
                    completion(videoUrl)
                } else {
                    print("音视频合成失败: \(assetExport.error?.localizedDescription ?? "unknown")")
                    completion(nil)
                }
            }
        }
    }
    
    //CGImage->CVPixelBuffer
    func pixelBuffer(from image: CGImage, size: CGSize) -> CVPixelBuffer? {
        let options : [NSObject:AnyObject] = [
            kCVPixelBufferCGImageCompatibilityKey : true as AnyObject,
            kCVPixelBufferCGBitmapContextCompatibilityKey : true as AnyObject
        ]
        
        var pxbuffer: CVPixelBuffer? = nil
        CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(size.width),
            Int(size.height),
            kCVPixelFormatType_32ARGB,
            options as CFDictionary,
            &pxbuffer
        )
        
        guard let pxbuffer else { return nil }
        CVPixelBufferLockBaseAddress(pxbuffer, CVPixelBufferLockFlags(rawValue: 0))
        defer {
            CVPixelBufferUnlockBaseAddress(pxbuffer, CVPixelBufferLockFlags(rawValue: 0))
        }
        
        guard let pxdata = CVPixelBufferGetBaseAddress(pxbuffer) else { return nil }
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(
            data: pxdata,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: 8,
            bytesPerRow: CVPixelBufferGetBytesPerRow(pxbuffer),
            space: rgbColorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue
        )
        context?.draw(image, in: CGRect(origin: .zero, size: size))
        
        return pxbuffer
    }
    
    //图片合成视频
    func writeImage(imgArr:Array<UIImage> ,movieName:String ,size:CGSize ,duration:CGFloat ,fps:Int ,completion: @escaping()-> Void)  {
        let finishOnMain = {
            DispatchQueue.main.async {
                completion()
            }
        }
        
        guard !imgArr.isEmpty, duration > 0, fps > 0 else {
            finishOnMain()
            return
        }
        
        let url = URL.domainPathWith(name: movieName)
        URL.domainPathClear(url: url)

        guard let videoWriter = try? AVAssetWriter(url: url, fileType: .mov) else {
            finishOnMain()
            return
        }
        
        let videoSettingS: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: size.width,
            AVVideoHeightKey: size.height
        ]
        let videoWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettingS)
        videoWriterInput.expectsMediaDataInRealTime = false
        
        let sourcePixelBufferAttributesDic: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32ARGB
        ]
        let adaptor = AVAssetWriterInputPixelBufferAdaptor(
            assetWriterInput: videoWriterInput,
            sourcePixelBufferAttributes: sourcePixelBufferAttributesDic
        )
        
        guard videoWriter.canAdd(videoWriterInput) else {
            finishOnMain()
            return
        }
        
        videoWriter.add(videoWriterInput)
        guard videoWriter.startWriting() else {
            finishOnMain()
            return
        }
        
        videoWriter.startSession(atSourceTime: .zero)
        
        let imageCount = imgArr.count
        let totalFrames = max(Int((duration * CGFloat(fps)).rounded()), imageCount)
        let frameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
        
        var frame = 0
        let queue = DispatchQueue(label: "mediaInputQueue")
        
        videoWriterInput.requestMediaDataWhenReady(on: queue) {
            while videoWriterInput.isReadyForMoreMediaData {
                if frame >= totalFrames {
                    videoWriterInput.markAsFinished()
                    videoWriter.finishWriting {
                        finishOnMain()
                    }
                    break
                }
                
                let progress = Double(frame) / Double(totalFrames)
                let imageIndex = min(Int(progress * Double(imageCount)), imageCount - 1)
                guard let cgImage = imgArr[imageIndex].cgImage,
                      let buffer = self.pixelBuffer(from: cgImage, size: size) else {
                    frame += 1
                    continue
                }
                
                let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frame))
                let state = adaptor.append(buffer, withPresentationTime: presentationTime)
                frame += 1
                
                if !state {
                    print("写入视频帧失败")
                    videoWriterInput.markAsFinished()
                    videoWriter.cancelWriting()
                    finishOnMain()
                    break
                }
            }
        }
    }
}
