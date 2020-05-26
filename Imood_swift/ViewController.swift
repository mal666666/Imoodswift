//
//  ViewController.swift
//  Imood_swift
//
//  Created by Mac on 2020/5/25.
//  Copyright © 2020 Mac. All rights reserved.
//

import UIKit
import Masonry

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.edgesForExtendedLayout = UIRectEdge.bottom
        //背景
        let backgroundIV :UIImageView = UIImageView.init(image: UIImage.init(named: "background"))
        self.view.addSubview(backgroundIV)
        //backgroundIV.frame = CGRect(x: 0,y: 0,width: 330,height: 330)
        backgroundIV.mas_makeConstraints { (make) in
            make?.height.equalTo()(self.view.mas_width)
            make?.topMargin.equalTo()(self.view)
            make?.left.right()?.offset()(0)
        }
        //选照片滑条
        let scroll = UIScrollView.init()
        self.view.addSubview(scroll)
        scroll.backgroundColor = UIColor.init(red: 0.2, green: 0.42, blue: 0.54, alpha: 1.0)
        scroll.mas_makeConstraints { (make) in
            make?.height.offset()(80)
            make?.top.equalTo()(backgroundIV.mas_bottom)
            make?.left.right()?.offset()(0)
        }
        
    }


}

