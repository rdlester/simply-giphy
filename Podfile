# Uncomment the next line to define a global platform for your project
platform :ios, '9.0'

target 'SimplyGiphy' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for SimplyGiphy
  pod 'ReactiveCocoa'

  pod 'Gloss'

  pod 'Moya/ReactiveSwift', '~> 8.0'

  pod 'Moya-Gloss'

  pod 'Result'

  pod 'MaterialComponents'

  target 'SimplyGiphyTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'Quick'
    pod 'Nimble'
    # Need to redeclare pods here due to linker errors with @testable.
    # See https://github.com/CocoaPods/CocoaPods/issues/4384
    pod 'ReactiveCocoa'
    pod 'Gloss'
    pod 'Moya/ReactiveSwift', '~> 8.0'
    pod 'Moya-Gloss'
    pod 'Result'
    pod 'MaterialComponents'
  end

  target 'SimplyGiphyUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
