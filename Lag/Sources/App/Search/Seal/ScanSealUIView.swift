//
//  ScanSealUIView.swift
//  Lag
//
//  Created by Joe Blau on 9/19/20.
//

import UIKit

class ScanSealUIView: UIView {
    private let seal: Seal
    private let size = CGSize(width: 1024, height: 1024)
    private let descriptor = UIFont.systemFont(ofSize: 300, weight: .black).fontDescriptor.withDesign(.rounded)!
    private let byLineDescriptor = UIFont.systemFont(ofSize: 300, weight: .semibold).fontDescriptor.withDesign(.rounded)!
    private let colors = [UIColor(displayP3Red: 0.016, green: 0.482, blue: 0.820, alpha: 1).cgColor,
                          UIColor(displayP3Red: 0.380, green: 0.216, blue: 1.000, alpha: 1).cgColor]
    
    private lazy var outterSeal: UIView = {
        let v = UIView(frame: CGRect(origin: .zero, size: size))
        v.backgroundColor = .black
        v.layer.cornerRadius = size.width / 2
        return v
    }()
    
    private lazy var innerSeal: UIView = {
        let innerDiameter = size.width * 0.91
        let xy = (size.width - innerDiameter) / 2
        let v = UIView(frame: CGRect(x: xy, y: xy, width: innerDiameter, height: innerDiameter))

        let gradient = CAGradientLayer()

        gradient.frame = CGRect(x: 0, y: 0, width: innerDiameter, height: innerDiameter)
        gradient.colors = colors
        gradient.cornerRadius = innerDiameter / 2

        v.layer.insertSublayer(gradient, at: 0)
        return v
    }()
    
    private lazy var grade: UILabel = {
        let l = UILabel(frame: CGRect(x: 0, y: 100, width: size.width, height: 256))
        l.font = UIFont(descriptor: descriptor, size: 300)
        l.textAlignment = .center
        l.textColor = .white
        return l
    }()
    
    private lazy var serviceStack: UIStackView = {
        let topRow = UIStackView(arrangedSubviews: [
            ScanServiceView(systemName: "envelope.fill", name: "Email", isSupported: seal.supportedServices.contains(.f)),
            ScanServiceView(systemName: "hifispeaker.fill", name: "Audio", isSupported: seal.supportedServices.contains(.f)),
            ScanServiceView(systemName: "safari.fill", name: "Web", isSupported: seal.supportedServices.contains(.d)),
            ScanServiceView(systemName: "square.fill", name: "SD Video", isSupported: seal.supportedServices.contains(.d)),
            ScanServiceView(systemName: "person.fill", name: "1:1 Video Call", isSupported: seal.supportedServices.contains(.d)),
        ])
        topRow.translatesAutoresizingMaskIntoConstraints = false
        topRow.distribution = .fillEqually
        topRow.alignment = .center

        let bottomRow = UIStackView(arrangedSubviews: [
            ScanServiceView(systemName: "person.3.fill", name: "1:n Video Call", isSupported: seal.supportedServices.contains(.c)),
            ScanServiceView(systemName: "hand.thumbsup.fill", name: "Social", isSupported: seal.supportedServices.contains(.c)),
            ScanServiceView(systemName: "tv.fill", name: "HD Video", isSupported: seal.supportedServices.contains(.c)),
            ScanServiceView(systemName: "gamecontroller.fill", name: "Gaming", isSupported: seal.supportedServices.contains(.b)),
            ScanServiceView(systemName: "4k.tv.fill", name: "4k Video", isSupported: seal.supportedServices.contains(.a)),
        ])
        bottomRow.translatesAutoresizingMaskIntoConstraints = false
        bottomRow.distribution = .fillEqually
        bottomRow.alignment = .center
        
        let v = UIStackView(arrangedSubviews: [topRow, bottomRow])
        v.frame = CGRect(x: 102.4, y: 412, width: 819.2, height: 200)
        v.axis = .vertical
        v.distribution = .equalSpacing
        return v
    }()
    
    private lazy var details: UIStackView = {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let downloadAttachment = NSTextAttachment()
        downloadAttachment.image = UIImage(systemName: "arrow.down")?.withRenderingMode(.alwaysTemplate)
        downloadAttachment.setImageHeight(height: 50)

        let downloadAttributed = NSMutableAttributedString(attachment: downloadAttachment)
        downloadAttributed.append(NSAttributedString(string: seal.downloadSpeed, attributes: [ NSAttributedString.Key.paragraphStyle: paragraphStyle]))
        
        let downloadSpeed = UILabel()
        downloadSpeed.textColor = .white
        downloadSpeed.attributedText = downloadAttributed
        downloadSpeed.font = .monospacedSystemFont(ofSize: 70, weight: .light)

        let uploadAttachment = NSTextAttachment()
        uploadAttachment.image = UIImage(systemName: "arrow.up")?.withRenderingMode(.alwaysTemplate)
        uploadAttachment.setImageHeight(height: 50)
        
        let uploadAttributed = NSMutableAttributedString(attachment: uploadAttachment)
        uploadAttributed.append(NSAttributedString(string: seal.uploadSpeed, attributes: [ NSAttributedString.Key.paragraphStyle: paragraphStyle]))
        
        let uploadSpeed = UILabel()
        uploadSpeed.textColor = .white
        uploadSpeed.attributedText = uploadAttributed
        uploadSpeed.font = .monospacedSystemFont(ofSize: 70, weight: .light)

        let byLine = UILabel()
        byLine.text = "ʟᴀɢ.ᴀᴘᴘ ᴡɪ-ғɪ sᴘᴇᴇᴅ ᴛᴇsᴛ"
        byLine.font = UIFont(descriptor: byLineDescriptor, size: 32)
        byLine.textColor = UIColor.white.withAlphaComponent(0.3)
        byLine.sizeToFit()
        
        let v = UIStackView(arrangedSubviews: [downloadSpeed, uploadSpeed, byLine])
        v.frame = CGRect(x: 0, y: 668, width: size.width, height: 200)
        v.axis = .vertical
        v.alignment = .center
        v.distribution = .equalSpacing
        return v
    }()
    
    
    init(seal: Seal) {
        self.seal = seal
        super.init(frame: CGRect(origin: .zero, size: size))
        backgroundColor = .clear
        
        grade.text = seal.grade.description
        
        addSubview(outterSeal)
        addSubview(innerSeal)
        addSubview(grade)
        addSubview(serviceStack)
        addSubview(details)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        let context = UIGraphicsGetCurrentContext()!
        
        context.translateBy (x: size.width / 2, y: size.height / 2)
        context.scaleBy(x: 1, y: -1)

        centreArcPerpendicular(text: Constants.sealRing,
                               context: context,
                               radius: (size.width / 2) * 0.954,
                               angle: 0,
                               colour: .white,
                               font: UIFont.monospacedSystemFont(ofSize: 28, weight: .bold),
                               clockwise: true,
                               kerning: 1.2)
        
        centreArcPerpendicular(text: "\(seal.addressHash) • \(seal.location.description)",
                               context: context,
                               radius: (size.width / 2) * 0.87,
                               angle: .pi / 2,
                               colour: UIColor.white.withAlphaComponent(0.3),
                               font: .monospacedSystemFont(ofSize: 20, weight: .bold),
                               clockwise: true,
                               kerning: 1)

        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let imageView = UIImageView(image: image)

        addSubview(imageView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Prviate
    
    private func centreArcPerpendicular(text str: String, context: CGContext, radius r: CGFloat, angle theta: CGFloat, colour c: UIColor, font: UIFont, clockwise: Bool, kerning: CGFloat){
        let characters: [String] = str.map { String($0) }
        let l = characters.count
        let attributes = [NSAttributedString.Key.font: font]

        var arcs: [CGFloat] = []
        var totalArc: CGFloat = 0

        for i in 0 ..< l {
            arcs += [chordToArc(characters[i].size(withAttributes: attributes).width + kerning, radius: r)]
            totalArc += arcs[i]
        }

        let direction: CGFloat = clockwise ? -1 : 1
        let slantCorrection: CGFloat = clockwise ? -.pi / 2 : .pi / 2

        var thetaI = theta - direction * totalArc / 2

        for i in 0 ..< l {
            thetaI += direction * arcs[i] / 2
            centre(text: characters[i], context: context, radius: r, angle: thetaI, colour: c, font: font, slantAngle: thetaI + slantCorrection)
            thetaI += direction * arcs[i] / 2
        }
    }

    private func chordToArc(_ chord: CGFloat, radius: CGFloat) -> CGFloat {
        return 2 * asin(chord / (2 * radius))
    }

    private func centre(text str: String, context: CGContext, radius r: CGFloat, angle theta: CGFloat, colour c: UIColor, font: UIFont, slantAngle: CGFloat) {
        let attributes = [NSAttributedString.Key.foregroundColor: c, NSAttributedString.Key.font: font]
        context.saveGState()
        context.scaleBy(x: 1, y: -1)
        context.translateBy(x: r * cos(theta), y: -(r * sin(theta)))
        context.rotate(by: -slantAngle)
        let offset = str.size(withAttributes: attributes)
        context.translateBy (x: -offset.width / 2, y: -offset.height / 2)
        str.draw(at: CGPoint(x: 0, y: 0), withAttributes: attributes)
        context.restoreGState()
    }
}
