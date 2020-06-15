//
//  MGImage.swift
//  Imood_swift
//
//  Created by Mac on 2020/6/15.
//  Copyright © 2020 Mac. All rights reserved.
//

import Foundation
import UIKit

extension UIImage{
    //指定大小的正方形图片
    func squareImage(img: UIImage, size: CGSize) -> UIImage {
        var rect: CGRect
        let w = img.size.width
        let h = img.size.height
        if h >= w {
            rect = CGRect(x: 0, y: (h-w)/2, width: w, height: w)
        }else{
            rect = CGRect(x: (w-h)/2, y: 0, width: h, height: h)
        }
        let imageRef = img.cgImage?.cropping(to: rect)
        let thumbScale = UIImage.init(cgImage: imageRef!)
        UIGraphicsBeginImageContext(size)
        thumbScale.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext();
        return newImage
    }
}

