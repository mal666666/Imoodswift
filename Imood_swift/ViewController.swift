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
        //
        let backgroundIV :UIImageView = UIImageView.init(image: UIImage.init(named: "background"))
        self.view.addSubview(backgroundIV)
        //backgroundIV.frame = CGRect(x: 0,y: 0,width: 330,height: 330)
        backgroundIV.mas_makeConstraints { (make) in
            make?.height.equalTo()(self.view.mas_width)
            make?.topMargin.offset()(10)
            make?.left.right()?.offset()(0)
        }
        //
        let scroll = UIScrollView.init()
        self.view.addSubview(scroll)
//        scroll.mas_makeConstraints { (make) in
//            make?.height.equalTo()(self.view.mas_width)
//            //make?.top.equalTo(backgroundIV)
//            make?.left.right()?.offset()(0)
//        }
        
    }


}

