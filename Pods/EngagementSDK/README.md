# EngagementSDK - iOS
LiveLike’s Audience Engagement Suite gives broadcasters’ teams full control to activate their mobile audience through social features.

## Documentation
Check out our official [documentation page](https://docs.livelike.com/ios/index.html)

## Requirements
iOS 10.0+
Xcode 10.2+
Swift 4.2+

## Installation

### CocoaPods

[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects. For usage and installation instructions, visit their website. To integrate EnagagementSDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'EngagementSDK', '~> 1.0.0'
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks. To integrate EngagementSDK into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
git "git@bitbucket.org:livelike/livelike-ios-sdk.git" ~> 1.0.0
```

Next, import the SDK
```swift
import EngagementSDK
``` 

## Contributing

### Setup 

To get started you need to run the `make` file directly in the project directory in **Terminal.app**. This will install all of the development tools that EngagementSDK requires. 

- [SwiftLint](https://github.com/realm/SwiftLint)
- [SwiftFormat](https://github.com/nicklockwood/SwiftFormat)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen)

Additionally, EngagementSDK relies on some third party and open source dependencies. These dependencies are managed with [Carthage](https://github.com/Carthage/Carthage). To install the dependencies run `carthage bootstrap --platform ios` from the projects root directory.

### Xcode Project File

The `EngagementSDK.xcodeproj` is produced using the tool [XcodeGen](https://github.com/yonaskolb/XcodeGen). The source of truth for all build settings is located in the `project.yml` file. You can safely regenerate the `xcodeproj` file at any time by running `xcodegen` from the `LiveLikeSDK` directory. Hence, changes to the build settings **should not** be made directly in Xcode. They should be made in the main `project.yml` or supporting files, then integrated by regenerating the project.

## Project Structure

The project is comprised of a workspace containing two project files. One for the demo and testing app and the other for the SDK.

The SDK project includes two targets, `EngagementSDK` and `EngagementSDKDemo`. The `EngagementSDKDemo` has the same functionality as the `EngagementSDK` target, however also includes additional features to facilitate testing and demoing. It should be noted that `EngagementSDKDemo` is not meant for production use. 

## Publishing a Release

The Bitrise CI will automatically push a release when a version is tagged. 
A release should be tagged once the `release/` branch has been merged to master.

1. Create a git tag with the corresponding semantic version number and push to the remote repository(e.g. 1.2.2)
2. Update the `spec.version` in `EngagementSDK.podspec` to correspond to the above git tag.
3. Add the private spec to your CocoaPods installation (only need to do this once). `pod repo add livelikespecs git@bitbucket.org:livelike/livelike-sdk-ios-cocoa-specs.git`
4. Run `pod spec lint --allow-warnings EngagementSDK.podspec` to check for any errors.
5. Run `pod trunk push --allow-warnings EngagementSDK.podspec` to deploy your Podspec to Trunk and make it publicly available. See [CocoaPods Trunk](https://guides.cocoapods.org/making/getting-setup-with-trunk.html#cocoapods-trunk) for more info.
