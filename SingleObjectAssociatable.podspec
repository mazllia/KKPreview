Pod::Spec.new do |s|
  s.name             = 'SingleObjectAssociatable'
  s.version          = '1.0.0'
  s.summary          = 'A protocol use Objective-C runtime to associate a single value into conformed instance.'
  s.homepage         = "https://gitlab.kkinternal.com/kkbox-ios/#{s.name}"
  s.license          = { :type => 'Private', :text => 'All rights reserved to KKBOX.' }
  s.author           = { 'Dai, Peng-Yang' => 'pengyangdai@kkbox.com' }
  s.source           = { :git => "#{s.homepage}.git", :tag => s.version }
  s.ios.deployment_target = '7.0'
  s.swift_versions = ['3.0', '4.0', '4.1' '4.2', '5.0', '5.1']
  s.source_files = "Sources/#{s.name}/**/*"
end
