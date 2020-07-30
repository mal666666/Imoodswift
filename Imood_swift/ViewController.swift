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
import Toast_Swift

class ViewController: UIViewController {
    
    var imgCollectionView: UICollectionView!
    @objc dynamic var imgArr: [UIImage] = []
    let compo = Composition()
    var backgroundIV :UIImageView!
    let playBtn = UIButton()
    let videoTimeLab = UILabel()
    
    lazy var player: AVPlayer = {
        let player = AVPlayer.init(playerItem: AVPlayerItem.init(url: URL.domainPathWith(name: MGBase.photoMov)))
        let playerLayer = AVPlayerLayer.init(player: player)
        self.backgroundIV.layer.insertSublayer(playerLayer, at: 0)
        playerLayer.frame = self.backgroundIV.bounds
        player.addPeriodicTimeObserver(forInterval: CMTimeMake(value: 1, timescale: 10), queue: DispatchQueue.main) { [weak self]time in
            let loadTime = CMTimeGetSeconds(time)
            let totalTime = CMTimeGetSeconds(player.currentItem!.duration)
            if loadTime/totalTime == 1{
                player.seek(to: CMTime.zero)
                self?.playBtn.isSelected = false
            }
            //print(loadTime)
        }
        return player
    }()

    var needMix: Bool = true
    var squareImgArr: [UIImage] = []
    var myContext = 0

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.needMix = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.player.pause()
    }
    
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
        backgroundIV.addSubview(playBtn)
        playBtn.setImage(UIImage.init(named: "play_btn"), for: .normal)
        playBtn.setImage(UIImage.init(named: "play_btn"), for: .highlighted)
        playBtn.setImage(UIImage.from(color: UIColor.clear), for: .selected)
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
        layout.headerReferenceSize = CGSize(width: 5, height: 0)
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
        //
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(moveAction))
        imgCollectionView.isUserInteractionEnabled = true
        imgCollectionView.addGestureRecognizer(longPressGesture)
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
        slider.addTarget(self, action: #selector(sliderChange(s:)), for: .valueChanged)
        slider.minimumValue = 10
        slider.maximumValue = 30
        slider.value = 20
        slider.mas_makeConstraints { (make) in
            make?.left.equalTo()(selectBtn.mas_right)?.offset()(20)
            make?.right.offset()(-50)
            make?.centerY.equalTo()(selectBtn)
        }
        //显示视频总时间
        self.view.addSubview(videoTimeLab)
        videoTimeLab.textAlignment = .center
        videoTimeLab.font = UIFont.init(name: "Helvetica Neue", size: 16)
        videoTimeLab.adjustsFontSizeToFitWidth = true
        videoTimeLab.text = String.init(format: "%.0fs", slider.value)
        videoTimeLab.textColor = .black
        videoTimeLab.mas_makeConstraints { (make) in
            make?.width.offset()(50)
            make?.height.offset()(30)
            make?.right.offset()(0)
            make?.centerY.equalTo()(slider)
        }
        //
        addObserver(self, forKeyPath: "imgArr", options: .new, context: &myContext)
    
    }
    //
    @objc func sliderChange(s:UISlider) -> Void {
        videoTimeLab.text = String.init(format: "%.0fs", s.value)
        self.needMix = true
    }
    //
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &myContext {
            self.needMix = true
            self.squareImgArr.removeAll()
            for image in self.imgArr {
                let img = image.squareImage(img: image, size: MGBase.videoSize, aspectFill: false)
                self.squareImgArr.append(img)
            }
         } else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    //选择音乐风格
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
    //选择照片
    func goImage(){
        let imagePickerVC = TZImagePickerController()
        imagePickerVC.maxImagesCount = 9
        imagePickerVC.modalPresentationStyle = .fullScreen
        self.present(imagePickerVC, animated: true, completion: nil)
        imagePickerVC.didFinishPickingPhotosHandle = {photos, aseets, isSelectOriginalPhoto in
            guard let ps = photos else {return}
            for photo in ps {
                let img = photo.squareImage(img: photo, size: MGBase.videoSize, aspectFill: true)
                self.imgArr.insert(img, at: self.imgArr.count)
            }
            self.imgCollectionView.reloadData()
        }
    }
    
    @objc func playBtnClick(btn: UIButton) {
        guard self.squareImgArr.count>0 else {
            self.view.makeToast("请添加照片")
            return
        }
        btn.isSelected = !btn.isSelected
        if btn.isSelected{
            self.playBtn.setBackgroundImage(UIImage.from(color: .clear), for: .normal)
            
            let videoText = videoTimeLab.text!.index(videoTimeLab.text!.startIndex, offsetBy: 1)
            let videoTime:String = String((videoTimeLab.text?.prefix(through: videoText))!)
                        
            if self.needMix  {
                self.compo.writeImage(imgArr: self.squareImgArr, movieName: MGBase.photoMov, size: MGBase.videoSize, duration: CGFloat(Float(videoTime)!), fps: 24, completion: {
                    self.compo.audioVideoComposition(videoTime: Int64(videoTime)!) { (url) in
                        DispatchQueue.main.async {
                            self.needMix = false
                            self.player.replaceCurrentItem(with: AVPlayerItem.init(url: url!))
                            self.player.play()
                        }
                    }
                })
            }else{
                self.player.play()
            }
        }else{
            player.pause()
        }
    }
    
    @objc func moveAction(_ longGes: UILongPressGestureRecognizer?) {
        if longGes?.state == .began {
            let point = longGes?.location(in: longGes?.view)
            let selectPath:IndexPath? = imgCollectionView.indexPathForItem(at: point!)
            guard (selectPath != nil && selectPath?.section == 0) else {return}
            imgCollectionView.beginInteractiveMovementForItem(at: selectPath!)
            let cell: ImageViewCell = self.imgCollectionView.cellForItem(at: selectPath!) as! ImageViewCell
            cell.deleteBtn.isHidden = false
            cell.deleteBtn.tag = selectPath!.row
            cell.deleteBtn.addTarget(self, action: #selector(deleteItemAction), for: .touchUpInside)
            DispatchQueue.main.asyncAfter(deadline: .now()+3) {
                cell.deleteBtn.isHidden = true
            }
        } else if longGes?.state == .changed {
            imgCollectionView.updateInteractiveMovementTargetPosition(longGes?.location(in: longGes?.view) ?? CGPoint.zero)
        } else if longGes?.state == .ended {
            imgCollectionView.endInteractiveMovement()
        } else {
            imgCollectionView.cancelInteractiveMovement()
        }
    }
    
    @objc func deleteItemAction(_ btn: UIButton?) {
        imgArr.remove(at: btn?.tag ?? 0)
        imgCollectionView.reloadData()
    }
}

extension ViewController: UICollectionViewDelegate{
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        if indexPath.section == 1 {
            goImage()
        }else{
            player.pause()
            self.playBtn.setBackgroundImage(imgArr[indexPath.row], for: .normal)
        }
    }
}

extension ViewController: UICollectionViewDataSource{
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch section {
        case 0://图片
            return imgArr.count
        case 1://加号
            return 1
        default:
            return 0
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell:ImageViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "cellID", for: indexPath) as! ImageViewCell
        cell.backgroundColor = .clear
        if indexPath.section == 0 {
            cell.imgV.image = imgArr[indexPath.row]
        }else{
            cell.imgV.image = UIImage.init(named: "album_add")
        }
        cell.deleteBtn.isHidden = true
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let obj = imgArr[sourceIndexPath.item]
        imgArr.remove(at: sourceIndexPath.item)
        imgArr.insert(obj, at: destinationIndexPath.item)
        imgCollectionView.reloadData()
    }

}
