// ScanServiceView.swift
// Copyright (c) 2020 Submap

import UIKit

class ScanServiceView: UIView {
    
    private lazy var icon: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.tintColor = .white
        v.contentMode = .scaleAspectFit
        return v
    }()
    
    private lazy var title: UILabel = {
        let l = UILabel()
        l.translatesAutoresizingMaskIntoConstraints = false
        l.font = .systemFont(ofSize: 22)
        l.textColor = .white
        return l
    }()
    
    private lazy var stackView: UIStackView = {
        let v = UIStackView(arrangedSubviews: [icon, title])
        v.translatesAutoresizingMaskIntoConstraints = false
        v.alignment = .center
        v.axis = .vertical
        return v
    }()
    
    init(systemName: String, name: String, isSupported: Bool) {
  
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        icon.image = UIImage(systemName: systemName)
        title.text = name
        
        addSubview(stackView)
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: self.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor),
            stackView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
        ])
        
        NSLayoutConstraint.activate([
            icon.widthAnchor.constraint(equalToConstant: 58),
            icon.heightAnchor.constraint(equalToConstant: 58),
        ])
        stackView.alpha = isSupported ? 1.0 : 0.4
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
