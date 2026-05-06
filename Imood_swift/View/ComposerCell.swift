//
//  ComposerCell.swift
//  Imood_swift
//
//  Created by Mac on 2020/5/31.
//  Copyright © 2020 Mac. All rights reserved.
//

import UIKit

class ComposerCell: UICollectionViewCell {
    
    let titleLab = UILabel()
    let subTitleLab = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layer.cornerRadius = 5
        self.clipsToBounds = true

        self.contentView.addSubview(titleLab)
        titleLab.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        titleLab.textColor = MGBase.themeTextPrimary
        titleLab.layer.shadowColor = UIColor.black.cgColor
        titleLab.layer.shadowOffset = CGSize(width: 0, height: 1)
        titleLab.layer.shadowOpacity = 0.25
        titleLab.layer.shadowRadius = 2
        titleLab.mas_makeConstraints { (make) in
            make?.edges.install()
        }
        titleLab.textAlignment = .center
        
        self.contentView.addSubview(subTitleLab)
        subTitleLab.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        subTitleLab.textColor = MGBase.themeTextPrimary.withAlphaComponent(0.88)
        subTitleLab.mas_makeConstraints { (make) in
            make?.centerY.offset()(34)
            make?.left.right().offset()(0)
            make?.height.offset()(30)
        }
        subTitleLab.textAlignment = .center
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
