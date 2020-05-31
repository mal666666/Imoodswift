//
//  ComposerViewController.swift
//  Imood_swift
//
//  Created by Mac on 2020/5/27.
//  Copyright © 2020 Mac. All rights reserved.
//

import UIKit

class ComposerViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    var musicMixCollectionView: UICollectionView!
    //4种乐器
    let musicalInstrumentsArr = ["DRUM","BASS","GUITAR","MIDI"]
    
    //4种乐器代表的颜色
    let colorArr = [UIColor.init(red: 0.964, green: 0.419, blue: 0.388, alpha: 1.0)
        ,UIColor.init(red: 1.0, green: 0.627, blue: 0.219, alpha: 1.0)
        ,UIColor.init(red: 0.325, green: 0.709, blue: 0.839, alpha: 1.0)
        ,UIColor.init(red: 0.364, green: 0.8, blue: 0.796, alpha: 1.0)]
    //选中第几个乐器
    var musicalInstrumentsIndex = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.init(red: 0.2, green: 0.423, blue: 0.549, alpha: 1.0)
        //collectionView
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.headerReferenceSize = CGSize.init(width: MGBase.screen_width(), height: 10)
        musicMixCollectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout:layout)
        self.view.addSubview(musicMixCollectionView)
        musicMixCollectionView.delegate = self
        musicMixCollectionView.dataSource = self
        musicMixCollectionView.register(ComposerCell.self, forCellWithReuseIdentifier: "cellID")
        musicMixCollectionView.mas_makeConstraints { (make) in
            make?.topMargin.offset()(20)
            make?.left.right()?.offset()(0)
            make?.height.equalTo()(self.view.mas_width)?.offset()(MGBase.screen_width()/4+30)
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
            return CGSize.init(width: MGBase.screen_width()/2-5, height: MGBase.screen_width()/2-5)
        default:
            return CGSize.init(width: MGBase.screen_width()/5-10, height: MGBase.screen_width()/4)
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
            cell.titleLab.text = musicalInstrumentsArr[indexPath.row]
            cell.titleLab.font = UIFont.systemFont(ofSize: 30)
        }else{
            cell.backgroundColor = colorArr[musicalInstrumentsIndex]
            cell.titleLab.text = String(indexPath.row)
            cell.titleLab.font = UIFont.systemFont(ofSize: 20)
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.section == 0 {
            musicalInstrumentsIndex = indexPath.row
            musicMixCollectionView.reloadData()
            //headerReferenceSize会奔溃
            //musicMixCollectionView.reloadSections(IndexSet(integer: 1))
        }
    }
}
