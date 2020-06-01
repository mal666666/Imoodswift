//
//  ComposerViewController.swift
//  Imood_swift
//
//  Created by Mac on 2020/5/27.
//  Copyright © 2020 Mac. All rights reserved.
//

import UIKit
import AVFoundation

class ComposerViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    var musicMixCollectionView: UICollectionView!
    var player: AVPlayer!
    //4种乐器名字
    let musicalInstrumentsNameArr = ["DRUM","BASS","GUITAR","MIDI"]
    //4种乐器代表的颜色
    let colorArr = [UIColor.init(red: 0.964, green: 0.419, blue: 0.388, alpha: 1.0)
        ,UIColor.init(red: 1.0, green: 0.627, blue: 0.219, alpha: 1.0)
        ,UIColor.init(red: 0.325, green: 0.709, blue: 0.839, alpha: 1.0)
        ,UIColor.init(red: 0.364, green: 0.8, blue: 0.796, alpha: 1.0)]
    //选中第几个乐器
    var musicalInstrumentsIndex = 0
    //音乐类型
    var type: String! = nil
    //4x5种流行音乐元素
    let musicLXArr = [["LX-鼓1","LX-鼓2","LX-鼓3","LX-鼓4","LX-鼓5"]
        ,["LX-贝斯1","LX-贝斯2","LX-贝斯3","LX-贝斯4","LX-贝斯5"]
        ,["LX-主音吉他1","LX-主音吉他2","LX-主音吉他3","LX-主音吉他4","LX-主音吉他5"]
        ,["LX-节奏吉他1","LX-节奏吉他2","LX-节奏吉他3","LX-节奏吉他4","LX-节奏吉他5"]]
    
    let musicJSArr = [["JS-鼓1","JS-鼓2","JS-鼓3","JS-鼓4","JS-鼓5"]
        ,["JS-贝斯1","JS-贝斯2","JS-贝斯3","JS-贝斯4","JS-贝斯5"]
        ,["JS-主音吉他1","JS-主音吉他2","JS-主音吉他3","JS-主音吉他4","JS-主音吉他5"]
        ,["JS-节奏吉他1","JS-节奏吉他2","JS-节奏吉他3","JS-节奏吉他4","JS-节奏吉他5"]]
    
    let musicSNArr = [["SN-鼓1","SN-鼓2","SN-鼓3","SN-鼓4","SN-鼓5"]
        ,["SN-贝斯1","SN-贝斯2","SN-贝斯3","SN-贝斯4","SN-贝斯5"]
        ,["SN-吉他1","SN-吉他2","SN-吉他3","SN-吉他4","SN-吉他5"]
        ,["SN-键盘1","SN-键盘2","SN-键盘3","SN-键盘4","SN-键盘5"]]

    let musicDZArr = [["DZ-鼓1","DZ-鼓2","DZ-鼓3","DZ-鼓4","DZ-鼓5"]
        ,["DZ-贝斯1","DZ-贝斯2","DZ-贝斯3","DZ-贝斯4","DZ-贝斯5"]
        ,["DZ-DJ1","DZ-DJ2","DZ-DJ3","DZ-DJ4","DZ-DJ5"]
        ,["DZ-键盘1","DZ-键盘2","DZ-键盘3","DZ-键盘4","DZ-键盘5"]]
    
    //左进度
    let leftProgressLab = UILabel()
    //右进度
    let rightProgressLab = UILabel()
    //进度条
    let slider = UISlider()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.init(red: 0.2, green: 0.423, blue: 0.549, alpha: 1.0)
        //collectionView
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.headerReferenceSize = CGSize.init(width: MGBase.screenWidth, height: 10)
        musicMixCollectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout:layout)
        self.view.addSubview(musicMixCollectionView)
        musicMixCollectionView.delegate = self
        musicMixCollectionView.dataSource = self
        musicMixCollectionView.backgroundColor = .clear
        musicMixCollectionView.register(ComposerCell.self, forCellWithReuseIdentifier: "cellID")
        musicMixCollectionView.mas_makeConstraints { (make) in
            make?.topMargin.offset()(20)
            make?.left.right()?.offset()(0)
            make?.height.equalTo()(self.view.mas_width)?.offset()(MGBase.screenWidth/4+30)
        }
        //播放
        let playBtn = UIButton()
        musicMixCollectionView.addSubview(playBtn)
        playBtn.setImage(UIImage.init(named: "play"), for: .normal)
        playBtn.addTarget(self, action: #selector(backBtnClick), for: .touchUpInside)
        playBtn.mas_makeConstraints { (make) in
            make?.width.height()?.offset()(MGBase.screenWidth/3)
            make?.centerX.equalTo()(musicMixCollectionView)
            make?.top.offset()(MGBase.screenWidth/3+10)
        }
        //退出
        let backBtn = UIButton()
        self.view.addSubview(backBtn)
        backBtn.setImage(UIImage.init(named: "closed"), for: .normal)
        backBtn.addTarget(self, action: #selector(backBtnClick), for: .touchUpInside)
        backBtn.mas_makeConstraints { (make) in
            make?.width.height()?.offset()(40)
            make?.left.offset()(50)
            make?.bottomMargin.offset()(-20)
        }
        //合成音乐
        let mixBtn = UIButton()
        self.view.addSubview(mixBtn)
        mixBtn.setImage(UIImage.init(named: "fabu"), for: .normal)
        mixBtn.addTarget(self, action: #selector(mixBtnClick), for: .touchUpInside)
        mixBtn.mas_makeConstraints { (make) in
            make?.width.height()?.offset()(40)
            make?.right.offset()(-50)
            make?.bottomMargin.offset()(-20)
        }
        //录音
        let recordBtn = UIButton()
        self.view.addSubview(recordBtn)
        recordBtn.setImage(UIImage.init(named: "record"), for: .normal)
        recordBtn.addTarget(self, action: #selector(recordBtnClick), for: .touchUpInside)
        recordBtn.mas_makeConstraints { (make) in
            make?.width.height()?.offset()(50)
            make?.centerX.equalTo()(self.view.mas_centerX)
            make?.bottomMargin.offset()(-15)
        }
        //左进度
        self.view.addSubview(leftProgressLab)
        leftProgressLab.text = "00:00"
        leftProgressLab.textAlignment = .right
        leftProgressLab.adjustsFontSizeToFitWidth = true
        leftProgressLab.mas_makeConstraints { (make) in
            make?.width.offset()(50)
            make?.height.offset()(20)
            make?.left.offset()(10)
            make?.bottomMargin.offset()(-90)
        }
        //右进度
        self.view.addSubview(rightProgressLab)
        rightProgressLab.text = "00:00"
        rightProgressLab.textAlignment = .left
        rightProgressLab.adjustsFontSizeToFitWidth = true
        rightProgressLab.mas_makeConstraints { (make) in
            make?.width.offset()(50)
            make?.height.offset()(20)
            make?.right.offset()(-10)
            make?.bottomMargin.offset()(-90)
        }
        //进度条
        self.view.addSubview(slider)
        slider.mas_makeConstraints { (make) in
            make?.left.offset()(70)
            make?.right.offset()(-70)
            make?.centerY.equalTo()(leftProgressLab)
        }
    }
    
    @objc func backBtnClick(){
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func mixBtnClick(){
        
    }
    
    @objc func recordBtnClick(){
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch indexPath.section {
        case 0:
            return CGSize.init(width: MGBase.screenWidth/2-5, height: MGBase.screenWidth/2-5)
        default:
            return CGSize.init(width: MGBase.screenWidth/5-10, height: MGBase.screenWidth/4)
        }
    }
        
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 4
        case 1:
            return 5
        default:
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:ComposerCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellID", for: indexPath) as! ComposerCell
        if indexPath.section == 0 {
            cell.backgroundColor = colorArr[indexPath.row]
            cell.titleLab.text = musicalInstrumentsNameArr[indexPath.row]
        }else{
            cell.backgroundColor = colorArr[musicalInstrumentsIndex]
            cell.titleLab.text = String(indexPath.row)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            musicalInstrumentsIndex = indexPath.row
            musicMixCollectionView.reloadData()
            //headerReferenceSize会奔溃
            //musicMixCollectionView.reloadSections(IndexSet(integer: 1))
        }else if indexPath.section == 1{
            var temArr = [[]]
            switch type {
            case "流行":
                temArr = musicLXArr
                break;
            case "金属":
                temArr = musicJSArr
                break;
            case "思念":
                temArr = musicSNArr
                break;
            case "电子":
                temArr = musicDZArr
                break;
            default:
                temArr = musicLXArr
                break
            }
            
            let path: String = Bundle.main.path(forResource: (temArr[musicalInstrumentsIndex][indexPath.row] as! String), ofType: "mp3")!
            let palyerItem = AVPlayerItem.init(url: URL.init(fileURLWithPath: path))
            player = AVPlayer.init(playerItem: palyerItem)
            player.play()
            
        }
    }
}
