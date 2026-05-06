platform :ios, '15.6'

target 'Imood_swift' do
  use_frameworks!

  pod 'Masonry'
  pod 'TZImagePickerController'
  pod 'Toast-Swift'
  pod 'lottie-ios'
  
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.6'
    end
  end
end
