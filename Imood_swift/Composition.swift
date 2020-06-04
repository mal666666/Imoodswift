//
//  Composition.swift
//  Imood_swift
//
//  Created by Mac on 2020/6/3.
//  Copyright © 2020 Mac. All rights reserved.
//

import UIKit
import AVFoundation

class Composition: NSObject {
    //音乐合成沙河路经
    let exportMusicPath = "exportMusic.m4a"
    typealias mixSuccess = (URL)->()
    var mixSuccessBlock: mixSuccess! = nil
    
    func compositionWithArr(audioUrlArr: [URL], completion: @escaping (_ string: String?) -> Void){
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
            if (self.mixSuccessBlock != nil){
                self.mixSuccessBlock(url)
            }
            completion("ff")
        })
    }
    
//    func completion(completion: @escaping (_ string: String?) -> Void) {
//
//    }
}
