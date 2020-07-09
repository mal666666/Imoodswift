//
//  ImageViewCell.swift
//  Imood_swift
//
//  Created by Mac on 2020/6/5.
//  Copyright © 2020 Mac. All rights reserved.
//

import UIKit

class ImageViewCell: UICollectionViewCell {
    
    var imgV = UIImageView()
    let deleteBtn = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        //
        self.contentView.addSubview(imgV)
        imgV.backgroundColor = .clear
        imgV.mas_makeConstraints { (make) in
            make?.edges.install()
        }
        //
        self.contentView.addSubview(deleteBtn)
        deleteBtn.backgroundColor = .red
        deleteBtn.isHidden = true
        deleteBtn.mas_makeConstraints { (make) in
            make?.width.height()?.offset()(20)
            make?.right.top()?.offset()(0)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
