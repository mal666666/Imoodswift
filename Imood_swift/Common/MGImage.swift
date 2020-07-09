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
    //指定大小的正方形图片 aspectFill:true为满屏，false为正常
    func squareImage(img: UIImage, size: CGSize, aspectFill: Bool) -> UIImage {
        var rect: CGRect
        let w = img.size.width
        let h = img.size.height
        var scaleTransform: CGAffineTransform!
        var origin: CGPoint = .zero

        if h >= w {
            if aspectFill {
                rect = CGRect(x: 0, y: (h-w)/2, width: w, height: w)
            }else{
                rect = CGRect(x: 0, y: 0, width: w, height: h)
                let scaleRatio: CGFloat = size.height / h
                origin = CGPoint(x: (h-w)/2, y: 0)
                scaleTransform = CGAffineTransform(scaleX: scaleRatio, y: scaleRatio)
            }
        }else{
            if aspectFill{
                rect = CGRect(x: (w-h)/2, y: 0, width: h, height: h)
            }else{
                rect = CGRect(x: 0, y: 0, width: w, height: h)
                let scaleRatio: CGFloat = size.width / w
                origin = CGPoint(x: 0, y: (w-h)/2)
                scaleTransform = CGAffineTransform(scaleX: scaleRatio, y: scaleRatio)
            }
        }
        
        let imageRef = img.cgImage?.cropping(to: rect)
        let thumbScale = UIImage.init(cgImage: imageRef!)
        UIGraphicsBeginImageContext(size)
        if aspectFill {
            thumbScale.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }else{
            UIGraphicsGetCurrentContext()?.concatenate(scaleTransform)
            thumbScale.draw(at: origin)
        }
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext();
        return newImage
    }
    
    //颜色画图片
    static func from(color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()
        context!.setFillColor(color.cgColor)
        context!.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
