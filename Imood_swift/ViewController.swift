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
        backgroundIV.mas_makeConstraints { (make) in
            make?.height.offset()(MGBase.screen_width())
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
        //选音乐风格
        let selectBtn = UIButton()
        self.view.addSubview(selectBtn)
        selectBtn.setImage(UIImage.init(named: "music_add"), for: .normal)
        selectBtn.addTarget(self, action: #selector(btnClick), for: .touchUpInside)
        selectBtn.mas_makeConstraints { (make) in
            make?.width.height()?.offset()(35)
            make?.left.offset()(10)
            make?.top.equalTo()(scroll.mas_bottom)?.offset()(40)
        }
        //设置视频时间滑竿
        let slider = UISlider()
        self.view.addSubview(slider)
        slider.setThumbImage(UIImage.init(named: "faderKey"), for: .normal)
        slider.mas_makeConstraints { (make) in
            make?.left.equalTo()(selectBtn.mas_right)?.offset()(20)
            make?.right.offset()(-20)
            make?.centerY.equalTo()(selectBtn)
        }
    
    }
    @objc func btnClick(){
        let ac = UIAlertController.init(title: "提示", message: "请选择音乐风格", preferredStyle: .actionSheet)
        let cancelAC = UIAlertAction.init(title: "取消", style: .cancel) { (action) in
            
        }
        let itemS = ["流行","金属","思念","电子"]
        ac.addAction(cancelAC)
        for item in itemS {
            let action = UIAlertAction.init(title: item, style: .default) { (action) in
                let composerVC = ComposerViewController()
                composerVC.modalPresentationStyle = .fullScreen
                self.present(composerVC, animated: true) {
                }
            }
            ac.addAction(action)
        }
        
        self.present(ac, animated: true) {
            
        }
        
    }
}

