//
//  ImageCache.swift
//  Santa
//
//  Created by Christian Braun on 05.12.19.
//

import UIKit

public struct ImageCache {
    fileprivate var cache = NSCache<NSString, UIImage>()
    public var countLimit: Int {
        set {
            cache.countLimit = newValue
        }
        get {
            cache.countLimit
        }
    }

    public init() {
        cache.countLimit = 15
    }

    public func add(url: String, image: UIImage) {
        cache.setObject(image, forKey: url as NSString)
    }

    public func get(url: String) -> UIImage? {
        return cache.object(forKey: url as NSString)
    }

    public func invalidate() {
        cache.removeAllObjects()
    }
}
