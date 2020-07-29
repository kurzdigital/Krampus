# Santa

[![Version](https://img.shields.io/cocoapods/v/Santa.svg?style=flat)](https://cocoapods.org/pods/Santa)
[![License](https://img.shields.io/cocoapods/l/Santa.svg?style=flat)](https://cocoapods.org/pods/Santa)
[![Platform](https://img.shields.io/cocoapods/p/Santa.svg?style=flat)](https://cocoapods.org/pods/Santa)

<div align="center"><img src="https://github.com/kurzdigital/Santa/blob/master/Santa.png" width="400" /></div>

A resource based network communication lib inspired by the first episode of the [Swift Talk](https://talk.objc.io/episodes/S01E1-tiny-networking-library) webshow.
It decouples the definition of resources and the required network stack to make the actual network call.

So this type of request:
```Swift
let request = URLRequest(url: URL(string: "your-url") !)
URLSession.shared.dataTask(with: request) { data, response, error in
    let httpResponse = response as! HTTPURLResponse
    guard httpResponse.statusCode == 200 else {
        fatalError()
    }
    let products = try !JSONDecoder().decode(Products.self, from: data!)
    // Some code to display products on screen
}
```

Can be written with Santa this way:

```Swift
let resource = DataResource(url: "your-url", method: .get, body: nil) { data in
    return try JSONDecoder().decode(Products.self, from: data)
}

ImplWebservice().load(resource: resource) { products, error in
    if let error = error {
        // do error handling
    }

    // Some code to display products on screen
}
```

This way resources can easily be placed right where they belong. As a part of the objects they are ment to fetch.

```Swift
extension Products {
    static var all: DataResource < Products > {
        return DataResource(url: url, method: .get, body: nil) { data in
            return try JSONDecoder().decode(Products.self, from: data)
        }
    }
}
```

## Features
* Support for custom authorization
* Background download tasks
* Cancelling of running URLSessionTasks
* ImageCache based on the url
* Error handling for error status codes and network problems

## Requirements
* Swift 5
* iOS 9.0 or newer

## Installation

Santa is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Santa'
```

## TODO

* Write more tests
* Extend mocked webservice to enable network independent tests (Download tasks, etc.)
* Add usage description
* Implement Upload Tasks

## Author

Christian Braun

## License

Santa is available under the MIT license. See the LICENSE file for more info.
