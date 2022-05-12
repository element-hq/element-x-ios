/*
 Copyright 2019 New Vector Ltd
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

import UIKit

final class ActivityIndicatorView: UIView {
    
    // MARK: - Constants
    
    private enum Constants {
        static let cornerRadius: CGFloat = 5.0
        static let activityIndicatorMargin = CGSize(width: 30.0, height: 30.0)
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    @IBOutlet private weak var activityIndicatorBackgroundView: UIView!
    
    // MARK: Public
    
    var color: UIColor? {
        get {
            return activityIndicatorView.color
        }
        set {            
            activityIndicatorView.color = newValue
        }
    }
    
    // MARK: - Setup
    
    private func commonInit() {        
        activityIndicatorBackgroundView.layer.masksToBounds = true
    }
    
    convenience init() {
        self.init(frame: CGRect.zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNibContent()
        commonInit()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNibContent()
        commonInit()
    }
    
    // MARK: - Overrides
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: activityIndicatorView.intrinsicContentSize.width + Constants.activityIndicatorMargin.width,
                      height: activityIndicatorView.intrinsicContentSize.height + Constants.activityIndicatorMargin.height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        activityIndicatorBackgroundView.layer.cornerRadius = Constants.cornerRadius
    }
    
    // MARK: - Public
    
    func startAnimating() {
        activityIndicatorView.startAnimating()
    }
    
    func stopAnimating() {
        activityIndicatorView.stopAnimating()
    }
}

private extension UIView {
    static var nib: UINib {
      return UINib(nibName: String(describing: self), bundle: Bundle(for: self))
    }
    
    func loadNibContent() {
      let layoutAttributes: [NSLayoutConstraint.Attribute] = [.top, .leading, .bottom, .trailing]
      for case let view as UIView in type(of: self).nib.instantiate(withOwner: self, options: nil) {
        view.translatesAutoresizingMaskIntoConstraints = false
        addSubview(view)
        NSLayoutConstraint.activate(layoutAttributes.map { attribute in
          NSLayoutConstraint(
            item: view, attribute: attribute,
            relatedBy: .equal,
            toItem: self, attribute: attribute,
            multiplier: 1, constant: 0.0
          )
        })
      }
    }
}
