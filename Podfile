target 'Sample App' do
    use_frameworks!
    pod 'EngagementSDK'
    pod 'WalletConnectSwift'
end

platform :ios, '11.0' # set IPHONEOS_DEPLOYMENT_TARGET for the pods project
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end
