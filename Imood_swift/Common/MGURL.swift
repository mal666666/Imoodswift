//
//  MGURL.swift
//  Imood_swift
//
//  Created by Mac on 2020/6/15.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation

extension URL{
    static func bundlePathWith(resouce: String ,type: String) -> URL {
        return URL.init(fileURLWithPath: Bundle.main.path(forResource: resouce, ofType: type)!)
    }
    
    static func domainPathWith(path: String) -> URL {
        return URL.init(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.documentDirectory, .allDomainsMask, true).first! + "/" + path)
    }
    
    static func domainPathClear(url: URL){
      //写入前删除
      if FileManager.default.fileExists(atPath: url.path) {
          do {
              try FileManager.default.removeItem(at: url)
          } catch {
              print(url.path + "删除失败")
          }
      }
    }
}
