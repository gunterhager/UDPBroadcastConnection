# UDPBroadcastConnection

<a href="https://developer.apple.com/swift"><img src="https://img.shields.io/badge/Language-Swift 4-orange.svg" alt="Language: Swift 4.2" /></a>

<a href="https://github.com/Carthage/Carthage"><img src="https://img.shields.io/badge/Carthage-compatible-brightgreen.svg" alt="Carthage compatible" /></a>

Framework to send UDP broadcast messages and listen to responses using a [Dispatch](https://developer.apple.com/reference/dispatch) dispatch source.

## Requirements

iOS 9.3+, Swift 4.2

## Usage

An example app is included demonstrating UDPBroadcastConnection's functionality. The example probably won't work for you out of the box since you need someone to listen and respond on the correct UDP port on your network.

### Getting Started

Create a `UDPBroadcastConnection` on port `35602` with a closure that handles the response:

```swift
broadcastConnection = UDPBroadcastConnection(port: 35602) { [unowned self] (response: (ipAddress: String, port: Int, response: [UInt8])) -> Void in
    print("Received from \(response.ipAddress):\(response.port):\n\n\(response.response)")
}
```

Note: Make sure to keep a strong reference to `broadcastConnection` (e.g. by storing it in a property).


## Installation

### Carthage

Add the following line to your [Cartfile](https://github.com/Carthage/Carthage/blob/master/Documentation/Artifacts.md#cartfile).

```
github "gunterhager/UDPBroadcastConnection"
```

Then run `carthage update`.

### Manually

Just drag and drop the `.swift` files in the `UDPBroadcastConnection` folder into your project.

## License

`UDPBroadcastConnection` is available under the MIT license. See the [LICENSE](https://github.com/gunterhager/UDPBroadcastConnection/blob/master/LICENSE) file for details.


Made with ❤ at [all about apps](https://www.allaboutapps.at).

[<img src="https://github.com/gunterhager/UDPBroadcastConnection/blob/master/Resources/aaa_logo.png" height="60" alt="all about apps" />](https://www.allaboutapps.at)
