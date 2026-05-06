//
//  ViewController.swift
//  Imood_swift
//
//  Created by Mac on 2020/5/25.
//  Copyright © 2020 Mac. All rights reserved.
//

import UIKit
import AVFoundation
import Masonry
import TZImagePickerController
import Toast_Swift

class ViewController: UIViewController {
    
    var imgCollectionView: UICollectionView!
    var imgArr: [UIImage] = [] {
        didSet {
            refreshPreparedImages()
        }
    }
    let compo = Composition()
    var backgroundIV :UIImageView!
    let playBtn = UIButton()
    let videoTimeLab = UILabel()
    private let durationSlider = UISlider()
    private let outputFPS = 24
    private var playerLayer: AVPlayerLayer?
    private var playerTimeObserver: Any?
    private let player = AVPlayer()
    private var isComposing = false
    private let loadingMaskView = UIView()
    private let loadingCardView = UIView()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    private let loadingTextLabel = UILabel()

    var needMix: Bool = true
    var squareImgArr: [UIImage] = []

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.needMix = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.player.pause()
        hideComposingLoading()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = MGBase.themeBackground
        self.edgesForExtendedLayout = .bottom
        self.navigationController?.navigationBar.tintColor = MGBase.themeAccent
        self.navigationController?.navigationBar.barStyle = .black
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: exportButton)
        //背景
        backgroundIV  = UIImageView.init(image: UIImage.init(named: "background"))
        self.view.addSubview(backgroundIV)
        backgroundIV.isUserInteractionEnabled = true
        backgroundIV.layer.cornerRadius = 12
        backgroundIV.clipsToBounds = true
        backgroundIV.mas_makeConstraints { (make) in
            make?.height.offset()(MGDevice.screenWidth)
            make?.topMargin.offset()(8)
            make?.left.right()?.offset()(0)
        }
        setupPlayer()
        //选音乐风格
        backgroundIV.addSubview(playBtn)
        let heroPlayIcon = UIImage.symbol(
            named: "play.circle.fill",
            pointSize: 72,
            weight: .regular,
            color: MGBase.themeTextPrimary.withAlphaComponent(0.92)
        )
        playBtn.setImage(heroPlayIcon, for: .normal)
        playBtn.setImage(heroPlayIcon, for: .highlighted)
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
        imgCollectionView.backgroundColor = MGBase.themePanel
        imgCollectionView.layer.cornerRadius = 10
        imgCollectionView.layer.borderWidth = 1
        imgCollectionView.layer.borderColor = MGBase.themePanelAlt.cgColor
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
        selectBtn.setImage(UIImage.composeMusicEntryIcon(waveformColor: MGBase.themeAccent, badgeColor: MGBase.themeAccentWarm), for: .normal)
        selectBtn.setImage(UIImage.composeMusicEntryIcon(waveformColor: MGBase.themeTextPrimary, badgeColor: MGBase.themeAccentWarm), for: .highlighted)
        selectBtn.addTarget(self, action: #selector(btnClick), for: .touchUpInside)
        selectBtn.backgroundColor = MGBase.themePanelAlt
        selectBtn.layer.cornerRadius = 8
        selectBtn.layer.borderWidth = 1
        selectBtn.layer.borderColor = MGBase.themeAccent.cgColor
        selectBtn.mas_makeConstraints { (make) in
            make?.width.height()?.offset()(35)
            make?.left.offset()(10)
            make?.top.equalTo()(imgCollectionView.mas_bottom)?.offset()(40)
        }
        //设置视频时间滑竿
        self.view.addSubview(durationSlider)
        durationSlider.setThumbImage(UIImage.sliderThumbImage(diameter: 18, fillColor: MGBase.themeTextPrimary, strokeColor: MGBase.themeAccent), for: .normal)
        durationSlider.addTarget(self, action: #selector(sliderChange(s:)), for: .valueChanged)
        durationSlider.minimumTrackTintColor = MGBase.themeAccent
        durationSlider.maximumTrackTintColor = MGBase.themePanelAlt
        durationSlider.minimumValue = 10
        durationSlider.maximumValue = 30
        durationSlider.value = 20
        durationSlider.mas_makeConstraints { (make) in
            make?.left.equalTo()(selectBtn.mas_right)?.offset()(20)
            make?.right.offset()(-50)
            make?.centerY.equalTo()(selectBtn)
        }
        //显示视频总时间
        self.view.addSubview(videoTimeLab)
        videoTimeLab.textAlignment = .center
        videoTimeLab.font = UIFont.init(name: "Helvetica Neue", size: 16)
        videoTimeLab.adjustsFontSizeToFitWidth = true
        videoTimeLab.text = String(format: "%.0fs", durationSlider.value)
        videoTimeLab.textColor = MGBase.themeTextPrimary
        videoTimeLab.mas_makeConstraints { (make) in
            make?.width.offset()(50)
            make?.height.offset()(30)
            make?.right.offset()(0)
            make?.centerY.equalTo()(durationSlider)
        }
        
        setupLoadingUI()
    }

    deinit {
        if let token = playerTimeObserver {
            player.removeTimeObserver(token)
            playerTimeObserver = nil
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = backgroundIV.bounds
    }
    
    private func setupPlayer() {
        if playerLayer == nil {
            let layer = AVPlayerLayer(player: player)
            layer.videoGravity = .resizeAspectFill
            backgroundIV.layer.insertSublayer(layer, at: 0)
            playerLayer = layer
        }
        
        if playerTimeObserver == nil {
            playerTimeObserver = player.addPeriodicTimeObserver(
                forInterval: CMTime(value: 1, timescale: 10),
                queue: .main
            ) { [weak self] time in
                guard let self,
                      let currentItem = self.player.currentItem else { return }
                let totalTime = CMTimeGetSeconds(currentItem.duration)
                guard totalTime.isFinite, totalTime > 0 else { return }
                let loadTime = CMTimeGetSeconds(time)
                if loadTime >= totalTime {
                    self.player.seek(to: .zero)
                    self.playBtn.isSelected = false
                }
            }
        }
    }
    
    private func refreshPreparedImages() {
        needMix = true
        squareImgArr = imgArr.map { image in
            image.squareImage(img: image, size: MGBase.videoSize, aspectFill: false)
        }
    }
    
    private func setupLoadingUI() {
        loadingMaskView.backgroundColor = UIColor.black.withAlphaComponent(0.34)
        loadingMaskView.alpha = 0
        loadingMaskView.isHidden = true
        view.addSubview(loadingMaskView)
        loadingMaskView.mas_makeConstraints { make in
            make?.edges.equalTo()(self.view)
        }
        
        loadingCardView.backgroundColor = MGBase.themePanel
        loadingCardView.layer.cornerRadius = 14
        loadingCardView.layer.borderWidth = 1
        loadingCardView.layer.borderColor = MGBase.themePanelAlt.cgColor
        loadingMaskView.addSubview(loadingCardView)
        loadingCardView.mas_makeConstraints { make in
            make?.centerX.equalTo()(self.loadingMaskView)
            make?.centerY.equalTo()(self.loadingMaskView)
            make?.width.offset()(180)
            make?.height.offset()(130)
        }
        
        loadingIndicator.color = MGBase.themeAccent
        loadingCardView.addSubview(loadingIndicator)
        loadingIndicator.mas_makeConstraints { make in
            make?.top.offset()(20)
            make?.centerX.equalTo()(self.loadingCardView)
        }
        
        loadingTextLabel.text = L10n.t("home_loading_composing")
        loadingTextLabel.textColor = MGBase.themeTextPrimary
        loadingTextLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        loadingTextLabel.textAlignment = .center
        loadingCardView.addSubview(loadingTextLabel)
        loadingTextLabel.mas_makeConstraints { make in
            make?.left.offset()(12)
            make?.right.offset()(-12)
            make?.bottom.offset()(-22)
        }
    }
    
    private func showComposingLoading() {
        loadingMaskView.isHidden = false
        loadingMaskView.alpha = 0
        loadingIndicator.startAnimating()
        UIView.animate(withDuration: 0.2) {
            self.loadingMaskView.alpha = 1
        }
    }
    
    private func hideComposingLoading() {
        UIView.animate(withDuration: 0.2, animations: {
            self.loadingMaskView.alpha = 0
        }) { _ in
            self.loadingIndicator.stopAnimating()
            self.loadingMaskView.isHidden = true
        }
    }
    
    //
    @objc func sliderChange(s:UISlider) -> Void {
        videoTimeLab.text = String(format: "%.0fs", s.value)
        self.needMix = true
    }
    //选择音乐风格
    @objc func btnClick(){
        let ac = UIAlertController.init(
            title: L10n.t("common_notice"),
            message: L10n.t("home_pick_style_message"),
            preferredStyle: .alert
        )
        ac.view.tintColor = MGBase.themeAccent
        let cancelAC = UIAlertAction.init(title: L10n.t("common_cancel"), style: .cancel) { (action) in
            
        }
        ac.addAction(cancelAC)
        let styleOptions: [(key: String, title: String)] = [
            ("pop", L10n.t("style_pop")),
            ("metal", L10n.t("style_metal")),
            ("nostalgia", L10n.t("style_nostalgia")),
            ("electronic", L10n.t("style_electronic"))
        ]
        for item in styleOptions {
            let action = UIAlertAction.init(title: item.title, style: .default) { (action) in
                let composerVC = ComposerViewController()
                composerVC.modalPresentationStyle = .fullScreen
                composerVC.musicStyleKey = item.key
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
        imagePickerVC.didFinishPickingPhotosHandle = { [weak self] photos, _, _ in
            guard let self, let ps = photos else { return }
            let newImages = ps.map { photo in
                photo.squareImage(img: photo, size: MGBase.videoSize, aspectFill: true)
            }
            self.imgArr.append(contentsOf: newImages)
            self.imgCollectionView.reloadData()
        }
    }
    
    @objc func playBtnClick(btn: UIButton) {
        if isComposing {
            return
        }
        
        guard !squareImgArr.isEmpty else {
            self.view.makeToast(L10n.t("home_toast_add_photos"))
            return
        }
        btn.isSelected = !btn.isSelected
        if btn.isSelected {
            self.playBtn.setBackgroundImage(UIImage.from(color: .clear), for: .normal)
            let selectedDuration = durationSlider.value
            
            if self.needMix {
                isComposing = true
                showComposingLoading()
                self.compo.writeImage(
                    imgArr: self.squareImgArr,
                    movieName: MGBase.photoMov,
                    size: MGBase.videoSize,
                    duration: CGFloat(selectedDuration),
                    fps: outputFPS
                ) { [weak self] in
                    guard let self else { return }
                    self.compo.audioVideoComposition(videoTime: Int64(selectedDuration.rounded())) { [weak self] url in
                        guard let self else { return }
                        self.isComposing = false
                        self.hideComposingLoading()
                        guard let url else {
                            self.playBtn.isSelected = false
                            self.view.makeToast(L10n.t("home_toast_compose_failed_retry"))
                            return
                        }
                        self.needMix = false
                        self.player.replaceCurrentItem(with: AVPlayerItem(url: url))
                        self.player.play()
                    }
                }
            } else {
                self.player.play()
            }
        } else {
            player.pause()
        }
    }
    
    @objc func moveAction(_ longGes: UILongPressGestureRecognizer?) {
        if longGes?.state == .began {
            guard let point = longGes?.location(in: longGes?.view),
                  let selectPath = imgCollectionView.indexPathForItem(at: point),
                  selectPath.section == 0 else { return }
            imgCollectionView.beginInteractiveMovementForItem(at: selectPath)
            guard let cell = self.imgCollectionView.cellForItem(at: selectPath) as? ImageViewCell else { return }
            cell.deleteBtn.isHidden = false
            cell.deleteBtn.tag = selectPath.row
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
        guard let index = btn?.tag, imgArr.indices.contains(index) else { return }
        imgArr.remove(at: index)
        imgCollectionView.reloadData()
    }
    
    private lazy var exportButton: UIButton = {
        let view = UIButton(frame: CGRect(x: 0, y: 0, width: 50, height: 30))
        view.setTitle(L10n.t("home_export"), for: .normal)
        view.setTitleColor(MGBase.themeTextPrimary, for: .normal)
        view.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
        view.backgroundColor = MGBase.themePanelAlt
        view.layer.cornerRadius = 5
        view.layer.borderWidth = 1
        view.layer.borderColor = MGBase.themeAccent.cgColor
        view.addTarget(self, action: #selector(didClickExportButton), for: .touchUpInside)
        return view
    }()
    
    @objc func didClickExportButton() {
        if UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(MGBase.videoPathWith(name: MGBase.videoName)) {
            UISaveVideoAtPathToSavedPhotosAlbum(MGBase.videoPathWith(name: MGBase.videoName), nil, nil, nil)
            view.makeToast(L10n.t("home_toast_export_success"))
        }
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
            cell.imgV.contentMode = .scaleAspectFill
        }else{
            cell.imgV.image = UIImage.symbol(named: "plus", pointSize: 24, weight: .bold, color: MGBase.themeAccent)
            cell.imgV.contentMode = .center
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
