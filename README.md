# Krampus

[![Version](https://img.shields.io/cocoapods/v/Krampus.svg?style=flat)](https://cocoapods.org/pods/Krampus)
[![License](https://img.shields.io/cocoapods/l/Krampus.svg?style=flat)](https://cocoapods.org/pods/Krampus)
[![Platform](https://img.shields.io/cocoapods/p/Krampus.svg?style=flat)](https://cocoapods.org/pods/Krampus)

Krampus is [Santa's](https://github.com/kurzdigital/Santa) little helper and provides authorization for web requests.
Currently there exists an authorization implementation for keycloak. Supported are login with an auth code aswell as with username and password.
Furthermore Krampus handles refreshing the access token and stores the refresh token safely within the users keychain.
Krampus was designed to work seamless with the resource based network lib [Santa](https://github.com/kurzdigital/Santa).

Configure your authorization:

```Swift
let webservice = ImplWebservice()
lazy var authorization = {
    return Krampus.keycloakAuthorization(
        baseUrl: "https://keycloak-url.de",
        clientId: "client",
        realm: "realm",
        redirectUrl: "needed for login with auth code",
        keychain: KeycloakKeychain(credentialsServiceName: "KeychainTestKrampusLogin"),
        webservice: webservice)
}()
```

To login with a running keycloak instance: 

```Swift
authorization.login(withUsername: "username", password: "password") { result in
    switch result {
    case .success(let credentials):
        // The credentials are already saved within the keychain. 
        // Show the user that the login was successful
    case .failure(let error):
        // Handle error
    }
}
```

Enable authorization for Santa Webservice:

```Swift
let webservice = ImplWebservice()
webservice.authorization = authorization
```

## Features
### Keycloak
* Login with Auth Code
* Login with username and password
* Logout
* Handle access token refresh
* Store Keycloak credentials within the users keychain

## TODO
* Write more tests
* Provide usage documentation

## Requirements
* Swift 5
* iOS 9.0 or newer

## Installation

Krampus is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'Krampus'
```

## Author

Christian Braun

## License

Krampus is available under the MIT license. See the LICENSE file for more info.
