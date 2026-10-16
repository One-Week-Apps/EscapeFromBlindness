source 'https://github.com/CocoaPods/Specs.git'
#source 'https://github.com/IndoorAtlas/CocoaPods-Specs.git'
platform :ios, '15.0'
use_frameworks!

target 'EscapeFromBlindness' do
  # Comment the next line if you don't want to use dynamic frameworks
  
  pod 'SwiftGen', '~> 6.6'
  pod 'SwiftLint', '0.33.1'
  
  target 'EscapeFromBlindnessTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

# Xcode 27 n'accepte plus de cible inférieure à iOS 15 : on aligne aussi les Pods.
post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
    end
  end
end
