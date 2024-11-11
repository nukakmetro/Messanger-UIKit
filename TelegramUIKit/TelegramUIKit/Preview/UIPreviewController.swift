//
//  UIPreviewController.swift
//  TelegramUIKit
//
//  Created by surexnx on 08.11.2024.
//

import UIKit
import CustomBlurEffectView

protocol UIPreviewControllerDelegate: AnyObject {
    func dismiss()
}

class UIPreviewController: UIViewController {

    weak var delegate: UIPreviewControllerDelegate?

    var previewSize: CGSize = CGSize(width: 300, height: 400) {
        didSet {
            view.layoutIfNeeded()
        }
    }

    var tapGestureRecognizer: UITapGestureRecognizer {
        return UITapGestureRecognizer(target: self, action: #selector(handleTapSelfView))
    }

    var preview: UIView

    init(preview: UIView = UIView()) {
        self.preview = preview
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addGestureRecognizer(tapGestureRecognizer)
        view.backgroundColor = .clear
        setBlurEffect()
        setupLayout()
    }

    func setBlurEffect(blurView: UIVisualEffectView? = nil) {
        if let blurView {
            blurView.frame = view.bounds
            blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(blurView)
        } else {
            let customBlurEffectView = CustomBlurEffectView(
                radius: 20, // Set blur radius value. Defaults to `10` (CGFloat)
                color: .lightGray, // Set tint color value. Defaults to `nil` (UIColor?)
                colorAlpha: 0.3 // Set tint color alpha value. Defaults to `0.8` (CGFloat)
            )
            customBlurEffectView.frame = view.bounds
            view.addSubview(customBlurEffectView)
        }
    }

    func setPreview(preview: UIView) {
        self.preview = preview
    }

    func setupPreviewSize() {
    }

    func setupLayout() {
        preview.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(preview)
        NSLayoutConstraint.activate([
            preview.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
            preview.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            preview.heightAnchor.constraint(equalToConstant: previewSize.height),
            preview.widthAnchor.constraint(equalToConstant: previewSize.width)
        ])
    }

    @objc func handleTapSelfView() {
        delegate?.dismiss()
    }

    func copyPreview() -> UIView {
        return preview.copyView()
    }
}

extension UIView {
    fileprivate func copyView<T: UIView>() -> T {
        return NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self)) as! T
    }
}
