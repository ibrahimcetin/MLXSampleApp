//
//  PlatformImage.swift
//  MLXSampleApp
//
//  Created by İbrahim Çetin on 4.03.2025.
//

#if(canImport(AppKit))
import AppKit
typealias PlatformImage = NSImage
#elseif(canImport(UIKit))
import UIKit
typealias PlatformImage = UIImage
#endif

import SwiftUI

extension Image {
    init(platformImage: PlatformImage) {
#if(canImport(AppKit))
        self.init(nsImage: platformImage)
#elseif(canImport(UIKit))
        self.init(uiImage: platformImage)
#endif
    }
}
