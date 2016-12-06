# adbutler-ios-sdk

## Requirements

- iOS 9.0+
- Xcode 8.1+
- Swift 3.0.1+ or Objective-C

## Installation

### CocoaPods

To integrate adbutler-ios-sdk into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '9.0'
use_frameworks!

target '<Your Target Name>' do
    pod 'adbutler-ios-sdk', '~> 1.0'
end
```

If you want to be on the latest master branch:

```ruby
pod 'adbutler-ios-sdk', github: 'sparklit/adbutler-ios-sdk', branch: 'master'
```

Then, run `pod install` to download the code and integrate it into your project.

### Carthage

To integrate adbutler-ios-sdk into your Xcode project using Carthage, specify it in your `Cartfile`:

```ruby
github "sparklit/adbutler-ios-sdk" ~> 1.0
```

If you want to be on the latest master branch:

```ruby
github "sparklit/adbutler-ios-sdk" "master"
```

Then, run `carthage update` to build the framework and drag the built `AdButler.framework` into your Xcode project.

### Manually

Installation of adbutler-ios-sdk can be done manually by building and copying the framework into your project.

Another way is to add all swift files under `AdButler/AdButler` folder into your project.

## Usage

Please refer to https://adbutler.com/docs/api for up-to-date API documentation.

### Requesting Single Placement

To request a placement, you can build an instance of `PlacementRequestConfig` and specify the attributes you want to send:

```swift
let config: PlacementRequestConfig
AdButler.requestPlacement(with: config) { response in
  // handle response
}
```

### Requesting Multiple Placements

To request multiple placements, you need an array of `PlacementRequestConfig`s, and each for a placement respectively:

```swift
let configs: [PlacementRequestConfig]
AdButler.requestPlacements(with: configs) { response in
  // handle response
}
```

### Handling the Response

Placement(s) request will accept a completion block that is handed an instance of `Response`,
which is a Swift enum that will indicate success or other status for the request.

```swift
AdButler.requestPlacements(with: configs) { response in
  switch response {
  case .success(let placements): // ...
  case .badRequest(let httpStatusCode, let responseBody): //...
  case .badResponse(let responseBody): //...
  case .error(let error): //..
  }
}
```

Handle each case as appropriate for your application. In the case of `.success` you are given a list of `Placement`
that contains each placement requested.

### Request Pixel

You can request a pixel simply by giving the URL:

```swift
let url: URL
AdButler.requestPixel(with: url)
```

### Record Impression

When you have a `Placement`, you can record impression by:

```swift
let placement: Placement
placement.recordImpression()
```

### Record Click

Similarly, you can record click for a `Placement`:

```swift
let placement: Placement
placement.recordClick()
```

### Best Practice for Recording

The best practice is to record impression at the time when placement is actually visible on the screen; and record click when it is actually tapped.

### A Note About Objective-C

An additional alternative callback-based method is provided for Objective-C projects.
If you're using this SDK from an Objective-C project, you can request placements like this:

```objc
PlacementRequestConfig *config = [[PlacementRequestConfig alloc] initWithAccountId:153105 zoneId:214764 width:300 height:250 keywords:@[@"sample2"] click:nil];
[AdButler requestPlacementWithConfig:config success:^(NSString * _Nonnull status, NSArray<Placement *> * _Nonnull placements) {
    // :)
} failure:^(NSNumber * _Nullable statusCode, NSString * _Nullable responseBody, NSError * _Nullable error) {
    // :(
}];
```

## Sample Projects

Please check out the `Swift Sample` and `ObjC Sample` projects inside this repository to see more sample code about how to use this SDK.

# License

This SDK is released under the Apache 2.0 license. See [LICENSE](https://github.com/sparklit/adbutler-ios-sdk/tree/master/LICENSE) for more information.
