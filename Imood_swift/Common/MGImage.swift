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
        
        guard let sourceCGImage = img.cgImage,
              let imageRef = sourceCGImage.cropping(to: rect) else {
            return img
        }
        let thumbScale = UIImage(cgImage: imageRef)
        UIGraphicsBeginImageContext(size)
        if aspectFill {
            thumbScale.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        }else{
            UIGraphicsGetCurrentContext()?.concatenate(scaleTransform)
            thumbScale.draw(at: origin)
        }
        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return img
        }
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
    
    static func symbol(
        named: String,
        pointSize: CGFloat,
        weight: UIImage.SymbolWeight = .regular,
        color: UIColor
    ) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: pointSize, weight: weight)
        return UIImage(systemName: named, withConfiguration: config)?
            .withTintColor(color, renderingMode: .alwaysOriginal)
    }
    
    static func sliderThumbImage(
        diameter: CGFloat,
        fillColor: UIColor,
        strokeColor: UIColor
    ) -> UIImage {
        let size = CGSize(width: diameter, height: diameter)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let rect = CGRect(origin: .zero, size: size).insetBy(dx: 0.5, dy: 0.5)
            context.cgContext.setShadow(offset: CGSize(width: 0, height: 1), blur: 4, color: UIColor.black.withAlphaComponent(0.35).cgColor)
            let path = UIBezierPath(ovalIn: rect)
            fillColor.setFill()
            path.fill()
            strokeColor.setStroke()
            path.lineWidth = 1.5
            path.stroke()
        }
    }
    
    static func composeMusicEntryIcon(
        size: CGFloat = 22,
        waveformColor: UIColor,
        badgeColor: UIColor
    ) -> UIImage? {
        let canvas = CGSize(width: size, height: size)
        let renderer = UIGraphicsImageRenderer(size: canvas)
        return renderer.image { _ in
            let waveConfig = UIImage.SymbolConfiguration(pointSize: size * 0.82, weight: .semibold)
            let plusConfig = UIImage.SymbolConfiguration(pointSize: size * 0.44, weight: .bold)
            
            let wave = UIImage(systemName: "waveform.path", withConfiguration: waveConfig)?
                .withTintColor(waveformColor, renderingMode: .alwaysOriginal)
            let plus = UIImage(systemName: "plus.circle.fill", withConfiguration: plusConfig)?
                .withTintColor(badgeColor, renderingMode: .alwaysOriginal)
            
            let waveRect = CGRect(x: 0, y: size * 0.12, width: size * 0.92, height: size * 0.76)
            let plusRect = CGRect(x: size * 0.56, y: size * 0.02, width: size * 0.44, height: size * 0.44)
            wave?.draw(in: waveRect)
            plus?.draw(in: plusRect)
        }
    }
}
