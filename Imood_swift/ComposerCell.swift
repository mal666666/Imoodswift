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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.contentView.addSubview(titleLab)
        titleLab.mas_makeConstraints { (make) in
            make?.edges.install()
        }
        titleLab.textAlignment = .center
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
