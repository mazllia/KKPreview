Pod::Spec.new do |s|
  s.name             = 'KKPreview'
  s.version          = '0.0.1'
  s.summary          = 'Models and adaptors to support both 3D Touch and ContextMenu.'
  s.homepage         = "https://gitlab.kkinternal.com/kkbox-ios/#{s.name}"
  s.license          = { :type => 'Private', :text => 'All rights reserved to KKBOX.' }
  s.author           = { 'Dai, Peng-Yang' => 'pengyangdai@kkbox.com' }
  s.source           = { :git => "#{s.homepage}.git", :tag => s.version }
  s.ios.deployment_target = '9.0'
  s.swift_versions   = ['4.2', '5.0', '5.1']
  s.frameworks       = 'UIKit'

  s.default_subspecs = 'Core'

  s.subspec 'Core' do |ss|
    ss.source_files = 'Sources/KKPreview/**/*'
    ss.dependency 'SingleObjectAssociatable', '~> 1.0'
  end

  s.subspec 'PreviewableViewController' do |ss|
    ss.source_files  = 'Sources/PreviewableViewController/**/*'
  end
end
