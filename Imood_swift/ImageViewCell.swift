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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(imgV)
        imgV.backgroundColor = .clear
        imgV.mas_makeConstraints { (make) in
            make?.edges.install()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
