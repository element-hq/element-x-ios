//
//  ElementNavigationController.swift
//  ElementX
//
//  Created by Ismail on 20.06.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import UIKit

class ElementNavigationController: UINavigationController {
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        navigationBar.topItem?.backButtonDisplayMode = .minimal
    }
}
