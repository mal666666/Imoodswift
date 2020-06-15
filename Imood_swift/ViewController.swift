//
//  ViewController.swift
//  Imood_swift
//
//  Created by Mac on 2020/5/25.
//  Copyright © 2020 Mac. All rights reserved.
//

import UIKit
import Masonry
import TZImagePickerController

//protocol ViewControllerDelegate: class {
//    func test()
//}

class ViewController: UIViewController {
    
    var imgCollectionView: UICollectionView!
    var imgArr: [UIImage] = [UIImage.init(named: "album_add")!]
    let compo = Composition()
    var backgroundIV :UIImageView!
    var player: AVPlayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        self.edgesForExtendedLayout = UIRectEdge.bottom
        //背景
        backgroundIV  = UIImageView.init(image: UIImage.init(named: "background"))
        self.view.addSubview(backgroundIV)
        backgroundIV.isUserInteractionEnabled = true
        backgroundIV.mas_makeConstraints { (make) in
            make?.height.offset()(MGDevice.screenWidth)
            make?.topMargin.equalTo()(self.view)
            make?.left.right()?.offset()(0)
        }
        //选音乐风格
        let playBtn = UIButton()
        backgroundIV.addSubview(playBtn)
        playBtn.setImage(UIImage.init(named: "play_btn"), for: .normal)
        playBtn.addTarget(self, action: #selector(playBtnClick(btn:)), for: .touchUpInside)
        playBtn.mas_makeConstraints { (make) in
            make?.edges.install()
        }
        //collectionView选照片
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 5
        layout.minimumInteritemSpacing = 5
        layout.itemSize = CGSize.init(width: 70, height: 70)
        imgCollectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout:layout)
        self.view.addSubview(imgCollectionView)
        imgCollectionView.delegate = self
        imgCollectionView.dataSource = self
        imgCollectionView.showsHorizontalScrollIndicator = false
        imgCollectionView.backgroundColor = UIColor.init(red: 0.2, green: 0.42, blue: 0.54, alpha: 1.0)
        imgCollectionView.register(ImageViewCell.self, forCellWithReuseIdentifier: "cellID")
        imgCollectionView.mas_makeConstraints { (make) in
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
            make?.top.equalTo()(imgCollectionView.mas_bottom)?.offset()(40)
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
        let ac = UIAlertController.init(title: "提示", message: "请选择音乐风格", preferredStyle: .alert)
        let cancelAC = UIAlertAction.init(title: "取消", style: .cancel) { (action) in
            
        }
        ac.addAction(cancelAC)
        let itemS = ["流行","金属","思念","电子"]
        for item in itemS {
            let action = UIAlertAction.init(title: item, style: .default) { (action) in
                let composerVC = ComposerViewController()
                composerVC.modalPresentationStyle = .fullScreen
                composerVC.type = item
                self.present(composerVC, animated: true) {
                }
            }
            ac.addAction(action)
        }
        self.present(ac, animated: true) {
            
        }
    }
    
    func goImage(){
        let imagePickerVC = TZImagePickerController()
        imagePickerVC.maxImagesCount = 9
        imagePickerVC.modalPresentationStyle = .fullScreen
        self.present(imagePickerVC, animated: true, completion: nil)
        imagePickerVC.didFinishPickingPhotosHandle = {photos, aseets, isSelectOriginalPhoto in
            guard let ps = photos else {return}
            for photo in ps {
                self.imgArr.insert(photo, at: self.imgArr.count-1)
            }
            self.imgCollectionView.reloadData()
            
            var squareImgArr: [UIImage] = []
            for image in self.imgArr {
                let img = image.squareImage(img: image, size: MGBase.videoSize)
                squareImgArr.append(img)
            }
            self.compo.writeImage(imgArr: squareImgArr, moviePath: MGBase.photoMov, size: MGBase.videoSize, duration: 10, fps: 30)
        }
    }
    
    @objc func playBtnClick(btn: UIButton) {
        btn.isSelected = !btn.isSelected
        if (player == nil) {
            player = AVPlayer.init(url: URL.domainPathWith(path: MGBase.photoMov))
            let playerLayer = AVPlayerLayer.init(player: player)
            backgroundIV.layer.addSublayer(playerLayer)
            playerLayer.frame = backgroundIV.bounds
        }
        if btn.isSelected{
            player.play()
        }else{
            player.pause()
        }
        
    }
}

extension ViewController: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        if indexPath.row == self.imgArr.count-1 {
            goImage()
        }
    }

}

extension ViewController: UICollectionViewDataSource{
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imgArr.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:ImageViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellID", for: indexPath) as! ImageViewCell
        cell.backgroundColor = .gray
        cell.imgV.image = imgArr[indexPath.row]
        return cell
    }

}
