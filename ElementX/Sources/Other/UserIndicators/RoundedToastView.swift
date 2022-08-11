//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit

class RoundedToastView: UIView {
    private struct ShadowStyle {
        let offset: CGSize
        let radius: CGFloat
        let opacity: Float
    }
    
    private enum Constants {
        static let padding = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        static let activityIndicatorScale = CGFloat(0.75)
        static let imageViewSize = CGFloat(15)
        static let lightShadow = ShadowStyle(offset: .init(width: 0, height: 4), radius: 12, opacity: 0.1)
        static let darkShadow = ShadowStyle(offset: .init(width: 0, height: 4), radius: 4, opacity: 0.2)
    }
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        indicator.transform = .init(scaleX: Constants.activityIndicatorScale, y: Constants.activityIndicatorScale)
        indicator.startAnimating()
        return indicator
    }()
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: Constants.imageViewSize),
            imageView.heightAnchor.constraint(equalToConstant: Constants.imageViewSize)
        ])
        return imageView
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 5
        return stack
    }()
    
    private let label = UILabel()

    init(viewState: ToastViewState) {
        super.init(frame: .zero)
        setup(viewState: viewState)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup(viewState: ToastViewState) {
        backgroundColor = .clear
        clipsToBounds = true
        
        setupBackgroundMaterial()
        setupStackView()
        stackView.addArrangedSubview(toastView(for: viewState.style))
        stackView.addArrangedSubview(label)
        label.text = viewState.label
        label.textColor = .element.primaryContent
    }
    
    private func setupBackgroundMaterial() {
        let material = UIVisualEffectView(effect: UIBlurEffect(style: .systemMaterial))
        addSubview(material)
        material.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            material.topAnchor.constraint(equalTo: topAnchor),
            material.bottomAnchor.constraint(equalTo: bottomAnchor),
            material.leadingAnchor.constraint(equalTo: leadingAnchor),
            material.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }
    
    private func setupStackView() {
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.padding.top),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.padding.bottom),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.padding.left),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.padding.right)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = layer.frame.height / 2
    }
        
    private func toastView(for style: ToastViewState.Style) -> UIView {
        switch style {
        case .loading:
            return activityIndicator
        case .success:
            imageView.image = UIImage(systemName: "checkmark")
            return imageView
        case .error:
            imageView.image = UIImage(systemName: "xmark")
            return imageView
        }
    }
}
