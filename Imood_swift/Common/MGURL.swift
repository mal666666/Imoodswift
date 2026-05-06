//
//  MGURL.swift
//  Imood_swift
//
//  Created by Mac on 2020/6/15.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation

extension URL{
    //项目目录转URL
    static func bundlePathWith(resouce: String ,type: String) -> URL {
        guard let path = Bundle.main.path(forResource: resouce, ofType: type) else {
            return URL(fileURLWithPath: "/")
        }
        return URL(fileURLWithPath: path)
    }
    //沙盒转URL
    static func domainPathWith(name: String) -> URL {
        let basePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true).first ?? NSTemporaryDirectory()
        return URL(fileURLWithPath: basePath + "/" + name)
    }
    //写入前删除
    static func domainPathClear(url: URL){
      if FileManager.default.fileExists(atPath: url.path) {
          do {
              try FileManager.default.removeItem(at: url)
          } catch {
              print(url.path + "删除失败")
          }
      }
    }
    //计算大小
    static func fileSize(url: URL) -> Int{
        if FileManager.default.fileExists(atPath: url.path) {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                if let size = attributes[FileAttributeKey.size] as? NSNumber {
                    return size.intValue
                }
            } catch  {
                return 0
            }
        }
        return 0
    }
}
