//
//  ComposerViewController.swift
//  Imood_swift
//
//  Created by Mac on 2020/5/27.
//  Copyright © 2020 Mac. All rights reserved.
//

import UIKit
import AVFoundation
import Toast_Swift

class ComposerViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout {
    
    var musicMixCollectionView: UICollectionView!
    let player = AVPlayer()
    var timeObserver: Any?
    var playerItemEndObserver: NSObjectProtocol?
    //4种乐器名字
    let musicalInstrumentsNameArr = ["instrument_drum","instrument_bass","instrument_guitar","instrument_midi"]
    //4种乐器代表的颜色
    let colorArr = [UIColor(red: 255/255, green: 95/255, blue: 128/255, alpha: 1.0)
        ,UIColor(red: 255/255, green: 161/255, blue: 80/255, alpha: 1.0)
        ,UIColor(red: 90/255, green: 180/255, blue: 255/255, alpha: 1.0)
        ,UIColor(red: 89/255, green: 231/255, blue: 204/255, alpha: 1.0)]
    //选中第几个乐器
    var musicalInstrumentsIndex = 0
    //音乐类型
    var musicStyleKey: String?
    
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
    private let mainPlayButton = UIButton()
    private let mainPlayIndicator = UIActivityIndicatorView(style: .large)
    private let backButton = UIButton()
    private let saveButton = UIButton()
    private let recordButton = UIButton()
    //音乐合成
    let compo = Composition()
    //音乐元素数组
    var musicUrlArr: [URL] = [URL.init(fileURLWithPath: ""),URL.init(fileURLWithPath: ""),URL.init(fileURLWithPath: ""),URL.init(fileURLWithPath: "")]
    //音乐元素索引数组
    var musicIndexArr: [Int] = [-1,-1,-1,-1]
    private var preparedPlaybackKey: String?
    private var isPlaying = false {
        didSet {
            updateMainPlayButtonAppearance()
        }
    }
    private var isMixing = false {
        didSet {
            updateMainPlayButtonAppearance()
            updateInteractionState()
        }
    }
    private var isFinishing = false {
        didSet {
            updateInteractionState()
        }
    }
    //录音
    lazy var recoder: AVAudioRecorder? = {
        let audioSession: AVAudioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord)
            //增加录音音量
            try audioSession.overrideOutputAudioPort(.speaker)
            try audioSession.setActive(true)
        } catch let error {
            debugPrint("Couldn't force audio to speaker: \(error)")
        }
        
        var recoderSetting:[String: Any] = [:]
        
        recoderSetting[AVFormatIDKey] = NSNumber(value: Int32(kAudioFormatMPEG4AAC))
        recoderSetting[AVSampleRateKey] = NSNumber(value: 44100.0)
        recoderSetting[AVNumberOfChannelsKey] = NSNumber(value: 2)
        recoderSetting[AVEncoderAudioQualityKey] = NSNumber(value: AVAudioQuality.high.rawValue)
        recoderSetting[AVLinearPCMBitDepthKey] = NSNumber(value: 8)
        
        var re: AVAudioRecorder?
        do{
            URL.domainPathClear(url: URL.domainPathWith(name: MGBase.recoderName))
            re = try AVAudioRecorder.init(url: URL.domainPathWith(name: MGBase.recoderName), settings: recoderSetting)
            re?.prepareToRecord()
        }catch{
            print(error)
        }
        return re
    }()
    
    private var isPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var horizontalInset: CGFloat {
        0.0
    }
    
    private struct ComposerLayoutMetrics {
        let instrumentSide: CGFloat
        let patternWidth: CGFloat
        let patternHeight: CGFloat
        let instrumentContentWidth: CGFloat
        let mixHeight: CGFloat
        let playButtonSize: CGFloat
        let playButtonTop: CGFloat
    }
    
    private func layoutMetrics(for width: CGFloat) -> ComposerLayoutMetrics {
        let instrumentByWidth = max((width - 10.0) / 2.0, 120.0)
        let instrumentByHeight = max((MGDevice.screenHeight - (isPad ? 380.0 : 300.0)) / 2.0, 120.0)
        let instrumentMax: CGFloat = isPad ? 360.0 : instrumentByWidth
        let instrumentSide = min(instrumentByWidth, instrumentByHeight, instrumentMax)
        let instrumentContentWidth = instrumentSide * 2.0 + 10.0
        
        // Keep the 5-pad row visually aligned with the 2x2 instrument block width.
        let patternByWidth = max((instrumentContentWidth - 40.0) / 5.0, 44.0)
        let patternWidth = isPad ? min(patternByWidth, 190.0) : patternByWidth
        let patternHeight = isPad ? 120.0 : max(patternWidth * 1.05, 72.0)
        
        let mixHeight = instrumentSide * 2.0 + patternHeight + 70.0
        let playButtonSize = isPad ? min(max(instrumentSide * 0.62, 180.0), 230.0) : MGDevice.screenWidth / 3.0
        let playButtonTop = max(instrumentSide - playButtonSize / 2.0 + 15.0, 40.0)
        return ComposerLayoutMetrics(instrumentSide: instrumentSide,
                                     patternWidth: patternWidth,
                                     patternHeight: patternHeight,
                                     instrumentContentWidth: instrumentContentWidth,
                                     mixHeight: mixHeight,
                                     playButtonSize: playButtonSize,
                                     playButtonTop: playButtonTop)
    }
    
    deinit {
        clearPlayerObserver()
        clearPlayerItemEndObserver()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = MGBase.themeBackground
        ensurePlaybackAudioSession()
        //collectionView
        let layout = UICollectionViewFlowLayout.init()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.headerReferenceSize = CGSize(width: 1, height: 10)
        musicMixCollectionView = UICollectionView.init(frame: CGRect.zero, collectionViewLayout:layout)
        self.view.addSubview(musicMixCollectionView)
        musicMixCollectionView.delegate = self
        musicMixCollectionView.dataSource = self
        musicMixCollectionView.backgroundColor = MGBase.themePanel
        musicMixCollectionView.layer.cornerRadius = 14
        musicMixCollectionView.layer.borderWidth = 1
        musicMixCollectionView.layer.borderColor = MGBase.themePanelAlt.cgColor
        musicMixCollectionView.register(ComposerCell.self, forCellWithReuseIdentifier: "cellID")
        let listWidth = MGDevice.screenWidth - horizontalInset * 2.0
        let metrics = layoutMetrics(for: listWidth)
        musicMixCollectionView.mas_makeConstraints { (make) in
            make?.topMargin.offset()(self.isPad ? 24 : 20)
            make?.left.offset()(self.horizontalInset)
            make?.right.offset()(-self.horizontalInset)
            make?.height.offset()(metrics.mixHeight)
        }
        //播放
        musicMixCollectionView.addSubview(mainPlayButton)
        mainPlayButton.backgroundColor = MGBase.themePanelAlt.withAlphaComponent(0.55)
        mainPlayButton.layer.cornerRadius = 12
        mainPlayButton.addTarget(self, action: #selector(mixAndPlayBtnClick), for: .touchUpInside)
        mainPlayButton.mas_makeConstraints { (make) in
            make?.width.height()?.offset()(metrics.playButtonSize)
            make?.centerX.equalTo()(musicMixCollectionView)
            make?.top.offset()(metrics.playButtonTop)
        }
        mainPlayIndicator.hidesWhenStopped = true
        mainPlayIndicator.color = MGBase.themeTextPrimary
        mainPlayButton.addSubview(mainPlayIndicator)
        mainPlayIndicator.mas_makeConstraints { make in
            make?.centerX.equalTo()(self.mainPlayButton)
            make?.centerY.equalTo()(self.mainPlayButton)
        }
        //退出
        self.view.addSubview(backButton)
        backButton.setImage(UIImage.symbol(named: "xmark", pointSize: 18, weight: .bold, color: MGBase.themeTextPrimary), for: .normal)
        backButton.backgroundColor = MGBase.themePanelAlt
        backButton.layer.cornerRadius = 20
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = MGBase.themeAccent.cgColor
        backButton.addTarget(self, action: #selector(backBtnClick), for: .touchUpInside)
        backButton.mas_makeConstraints { (make) in
            make?.width.height()?.offset()(40)
            make?.left.offset()(self.horizontalInset + (self.isPad ? 24 : 50))
            make?.bottomMargin.offset()(-20)
        }
        //合成音乐
        self.view.addSubview(saveButton)
        saveButton.setImage(UIImage.symbol(named: "square.and.arrow.down.fill", pointSize: 18, weight: .semibold, color: MGBase.themeTextPrimary), for: .normal)
        saveButton.backgroundColor = MGBase.themePanelAlt
        saveButton.layer.cornerRadius = 20
        saveButton.layer.borderWidth = 1
        saveButton.layer.borderColor = MGBase.themeAccent.cgColor
        saveButton.addTarget(self, action: #selector(mixBtnClick), for: .touchUpInside)
        saveButton.mas_makeConstraints { (make) in
            make?.width.height()?.offset()(40)
            make?.right.offset()(-(self.horizontalInset + (self.isPad ? 24 : 50)))
            make?.bottomMargin.offset()(-20)
        }
        //录音
        self.view.addSubview(recordButton)
        recordButton.setImage(UIImage.symbol(named: "mic.fill", pointSize: 20, weight: .semibold, color: MGBase.themeTextPrimary), for: .normal)
        recordButton.setImage(UIImage.symbol(named: "stop.fill", pointSize: 20, weight: .bold, color: MGBase.themeAccentWarm), for: .selected)
        recordButton.backgroundColor = MGBase.themePanelAlt
        recordButton.layer.borderColor = MGBase.themeAccentWarm.cgColor
        recordButton.layer.cornerRadius = 25
        recordButton.addTarget(self, action: #selector(recordBtnClick(btn:)), for: .touchUpInside)
        recordButton.mas_makeConstraints { (make) in
            make?.width.height()?.offset()(50)
            make?.centerX.equalTo()(self.view.mas_centerX)
            make?.bottomMargin.offset()(-15)
        }
        //左进度
        self.view.addSubview(leftProgressLab)
        leftProgressLab.text = "00:00"
        leftProgressLab.font = UIFont.init(name: "Helvetica Neue", size: 16)
        leftProgressLab.textAlignment = .right
        leftProgressLab.adjustsFontSizeToFitWidth = true
        leftProgressLab.textColor = MGBase.themeTextPrimary
        leftProgressLab.mas_makeConstraints { (make) in
            make?.width.offset()(50)
            make?.height.offset()(20)
            make?.left.offset()(self.horizontalInset + (self.isPad ? 20 : 10))
            make?.bottomMargin.offset()(-90)
        }
        //右进度
        self.view.addSubview(rightProgressLab)
        rightProgressLab.text = "00:00"
        rightProgressLab.font = UIFont.init(name: "Helvetica Neue", size: 16)
        rightProgressLab.textAlignment = .left
        rightProgressLab.adjustsFontSizeToFitWidth = true
        rightProgressLab.textColor = MGBase.themeTextPrimary
        rightProgressLab.mas_makeConstraints { (make) in
            make?.width.offset()(50)
            make?.height.offset()(20)
            make?.right.offset()(-(self.horizontalInset + (self.isPad ? 20 : 10)))
            make?.bottomMargin.offset()(-90)
        }
        //进度条
        self.view.addSubview(slider)
        slider.minimumTrackTintColor = MGBase.themeAccent
        slider.maximumTrackTintColor = MGBase.themePanelAlt
        slider.isEnabled = false
        slider.mas_makeConstraints { (make) in
            make?.left.offset()(self.horizontalInset + (self.isPad ? 96 : 70))
            make?.right.offset()(-(self.horizontalInset + (self.isPad ? 96 : 70)))
            make?.centerY.equalTo()(leftProgressLab)
        }
        
        updateMainPlayButtonAppearance()
        updateInteractionState()
    }
    
    @objc func mixAndPlayBtnClick(){
        if isMixing || isFinishing {
            return
        }
        
        if isPlaying {
            pausePlayback()
            return
        }
        
        let assets = selectedAudioURLs()
        guard !assets.isEmpty else {
            view.makeToast(L10n.t("composer_toast_select_segments"))
            return
        }
        
        let playbackKey = self.playbackKey(for: assets)
        if preparedPlaybackKey == playbackKey {
            ensurePlaybackAudioSession()
            if let item = player.currentItem,
               CMTimeCompare(player.currentTime(), item.duration) >= 0 {
                player.seek(to: .zero)
            }
            startPlayback()
            return
        }
        
        mixAndPlay(audioURLs: assets, playbackKey: playbackKey)
    }
    
    @objc func backBtnClick(){
        if isMixing || isFinishing {
            return
        }
        isFinishing = true
        stopPlaybackAndRecording()
        URL.domainPathClear(url: URL.domainPathWith(name: MGBase.audioName))
        URL.domainPathClear(url: URL.domainPathWith(name: MGBase.recoderName))
        preparedPlaybackKey = nil
        self.view.makeToast(L10n.t("composer_toast_cancelled"))
        DispatchQueue.main.asyncAfter(deadline: .now()+1) {
            self.dismiss(animated: true)
        }
    }
    
    @objc func mixBtnClick(){
        if isMixing || isFinishing {
            return
        }
        isFinishing = true
        stopPlaybackAndRecording()
        
        let assets = selectedAudioURLs()
        guard !assets.isEmpty else {
            URL.domainPathClear(url: URL.domainPathWith(name: MGBase.audioName))
            preparedPlaybackKey = nil
            self.view.makeToast(L10n.t("composer_toast_saved"))
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                self.dismiss(animated: true)
            }
            return
        }
        
        isMixing = true
        let playbackKey = self.playbackKey(for: assets)
        compo.audioCompositionWithArr(audioUrlArr: assets) { [weak self] url in
            guard let self else { return }
            self.isMixing = false
            guard url != nil else {
                self.isFinishing = false
                self.view.makeToast(L10n.t("composer_toast_save_failed"))
                return
            }
            self.preparedPlaybackKey = playbackKey
            self.view.makeToast(L10n.t("composer_toast_saved"))
            DispatchQueue.main.asyncAfter(deadline: .now()+1) {
                self.dismiss(animated: true)
            }
        }
    }
    
    @objc func recordBtnClick(btn: UIButton){
        if isMixing || isFinishing {
            return
        }
        btn.isSelected = !btn.isSelected
        guard let recoder else {
            btn.isSelected = false
            self.view.makeToast(L10n.t("composer_toast_recorder_init_failed"))
            return
        }
        if btn.isSelected {
            ensurePlayAndRecordAudioSession()
            btn.layer.borderWidth = 2
            recoder.record()
            MGBase.recoderStartTime = self.player.currentTime()
        }else{
            btn.layer.borderWidth = 0
            recoder.stop()
            ensurePlaybackAudioSession()
        }
    }
    //播放音乐用url
    @objc func playWithUrl(url:URL){
        ensurePlaybackAudioSession()
        clearPlayerItemEndObserver()
        player.replaceCurrentItem(with: AVPlayerItem(url: url))
        clearPlayerObserver()
        registerPlayerItemEndObserver()
        timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 10), queue: DispatchQueue.main) { [weak self] time in
            guard let self else { return }
            let loadTime = CMTimeGetSeconds(time)
            guard let item = self.player.currentItem else { return }
            let totalTime = CMTimeGetSeconds(item.duration)
            guard totalTime.isFinite, totalTime > 0 else {
                self.slider.value = 0
                self.leftProgressLab.text = "00:00"
                self.rightProgressLab.text = "00:00"
                return
            }
            self.slider.value = Float(loadTime / totalTime)
            self.leftProgressLab.text = String.customTimeWithSecond(sec: Float(loadTime))
            self.rightProgressLab.text = String.customTimeWithSecond(sec: Float(totalTime))
        }
        startPlayback()
    }
    
    private func clearPlayerObserver() {
        if let observer = timeObserver {
            player.removeTimeObserver(observer)
            timeObserver = nil
        }
    }
    
    private func clearPlayerItemEndObserver() {
        if let observer = playerItemEndObserver {
            NotificationCenter.default.removeObserver(observer)
            playerItemEndObserver = nil
        }
    }
    
    private func registerPlayerItemEndObserver() {
        guard let currentItem = player.currentItem else { return }
        playerItemEndObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: currentItem,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.player.seek(to: .zero)
            self.slider.value = 0
            self.leftProgressLab.text = "00:00"
            self.isPlaying = false
        }
    }
    
    private func startPlayback() {
        player.play()
        isPlaying = true
    }
    
    private func pausePlayback() {
        player.pause()
        isPlaying = false
    }
    
    private func stopPlaybackAndRecording() {
        pausePlayback()
        player.seek(to: .zero)
        slider.value = 0
        leftProgressLab.text = "00:00"
        if let item = player.currentItem {
            let totalTime = CMTimeGetSeconds(item.duration)
            rightProgressLab.text = totalTime.isFinite && totalTime > 0
                ? String.customTimeWithSecond(sec: Float(totalTime))
                : "00:00"
        } else {
            rightProgressLab.text = "00:00"
        }
        if recoder?.isRecording == true {
            recoder?.stop()
            recordButton.isSelected = false
            recordButton.layer.borderWidth = 0
            ensurePlaybackAudioSession()
        }
    }
    
    private func selectedAudioURLs() -> [URL] {
        musicUrlArr.filter { $0.path != "/" && URL.fileSize(url: $0) > 0 }
    }
    
    private func playbackKey(for urls: [URL]) -> String {
        urls.map { $0.lastPathComponent }.joined(separator: "\n")
    }
    
    private func mixAndPlay(audioURLs: [URL], playbackKey: String) {
        let shouldShowLoading = audioURLs.count > 1
        if shouldShowLoading {
            isMixing = true
        }
        preparedPlaybackKey = nil
        
        if audioURLs.count == 1, let url = audioURLs.first {
            playWithUrl(url: url)
            preparedPlaybackKey = playbackKey
            return
        }
        
        compo.audioCompositionWithArr(audioUrlArr: audioURLs) { [weak self] url in
            guard let self else { return }
            if shouldShowLoading {
                self.isMixing = false
            }
            guard let url else {
                self.view.makeToast(L10n.t("composer_toast_select_segments"))
                return
            }
            self.playWithUrl(url: url)
            self.preparedPlaybackKey = playbackKey
        }
    }
    
    private func updateMainPlayButtonAppearance() {
        if isMixing {
            mainPlayButton.setImage(nil, for: .normal)
            mainPlayIndicator.startAnimating()
            return
        }
        
        mainPlayIndicator.stopAnimating()
        let symbolName = isPlaying ? "pause.fill" : "play.fill"
        let pointSize: CGFloat = isPlaying ? 42 : 46
        let icon = UIImage.symbol(
            named: symbolName,
            pointSize: pointSize,
            weight: .semibold,
            color: MGBase.themeTextPrimary
        )
        mainPlayButton.setImage(icon, for: .normal)
    }
    
    private func updateInteractionState() {
        let isBusy = isMixing || isFinishing
        mainPlayButton.isEnabled = !isBusy
        backButton.isEnabled = !isBusy
        saveButton.isEnabled = !isBusy
        recordButton.isEnabled = !isBusy
        backButton.alpha = isBusy ? 0.55 : 1
        saveButton.alpha = isBusy ? 0.55 : 1
        recordButton.alpha = isBusy ? 0.55 : 1
    }
    
    private func ensurePlaybackAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback)
            try session.setActive(true)
        } catch {
            print("音频播放会话初始化失败: \(error.localizedDescription)")
        }
    }
    
    private func ensurePlayAndRecordAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord)
            try session.overrideOutputAudioPort(.speaker)
            try session.setActive(true)
        } catch {
            print("录音会话初始化失败: \(error.localizedDescription)")
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width
        let metrics = layoutMetrics(for: width)
        switch indexPath.section {
        case 0:
            return CGSize(width: metrics.instrumentSide, height: metrics.instrumentSide)
        default:
            return CGSize(width: metrics.patternWidth, height: metrics.patternHeight)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let width = collectionView.bounds.width
        let metrics = layoutMetrics(for: width)
        let interitemSpace: CGFloat = 10.0
        let contentWidth: CGFloat
        if section == 0 {
            contentWidth = metrics.instrumentContentWidth
        } else {
            contentWidth = metrics.patternWidth * 5.0 + interitemSpace * 4.0
        }
        let inset = max((width - contentWidth) / 2.0, 0)
        return UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
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
            cell.layer.borderColor = UIColor.white.withAlphaComponent(0.14).cgColor
            cell.layer.borderWidth = 1
            cell.titleLab.text = L10n.t(musicalInstrumentsNameArr[indexPath.row])
            cell.titleLab.textColor = MGBase.themeTextPrimary
            cell.subTitleLab.isHidden = false
            cell.subTitleLab.textColor = MGBase.themeTextPrimary.withAlphaComponent(0.85)
            cell.subTitleLab.text = "\(musicIndexArr[indexPath.row])" == "-1" ? "" : "\(musicIndexArr[indexPath.row])"
        }else{
            cell.backgroundColor = colorArr[musicalInstrumentsIndex].withAlphaComponent(0.82)
            cell.layer.borderColor = UIColor.white.withAlphaComponent(0.10).cgColor
            cell.layer.borderWidth = 1
            cell.titleLab.text = String(indexPath.row)
            cell.titleLab.textColor = MGBase.themeTextPrimary
            cell.subTitleLab.isHidden = true
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if isMixing || isFinishing {
            return
        }
        if indexPath.section == 0 {
            musicalInstrumentsIndex = indexPath.row
            musicMixCollectionView.reloadData()
            //headerReferenceSize会奔溃
            //musicMixCollectionView.reloadSections(IndexSet(integer: 1))
        }else if indexPath.section == 1{
            var temArr: [[String]] = musicLXArr
            switch musicStyleKey {
            case "pop":
                temArr = musicLXArr
            case "metal":
                temArr = musicJSArr
            case "nostalgia":
                temArr = musicSNArr
            case "electronic":
                temArr = musicDZArr
            default:
                temArr = musicLXArr
            }
            
            let url = URL.bundlePathWith(resouce: temArr[musicalInstrumentsIndex][indexPath.row], type: "mp3")
            if musicIndexArr[musicalInstrumentsIndex] != indexPath.row {
                musicIndexArr[musicalInstrumentsIndex] = indexPath.row
                musicUrlArr[musicalInstrumentsIndex] = url
                preparedPlaybackKey = nil
                self.playWithUrl(url: url)
            }else{
                musicIndexArr[musicalInstrumentsIndex] = -1
                musicUrlArr[musicalInstrumentsIndex] = URL.init(fileURLWithPath: "")
                preparedPlaybackKey = nil
                self.pausePlayback()
            }
            musicMixCollectionView.reloadData()
        }
    }
}
