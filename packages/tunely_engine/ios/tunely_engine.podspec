Pod::Spec.new do |s|
  s.name             = 'tunely_engine'
  s.version          = '0.0.1'
  s.summary          = 'On-device audio engine for Tunely.'
  s.description      = 'Decodes with AVFoundation and encodes AAC/M4A/M4R/WAV/FLAC (Apple), MP3 (LAME) and OGG (libvorbis).'
  s.homepage         = 'https://tunely.app'
  s.license          = { :type => 'Proprietary', :text => 'Copyright Marberx' }
  s.author           = { 'Marberx' => 'support@tunely.app' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*.swift'
  s.dependency 'Flutter'
  s.platform         = :ios, '16.0'
  s.frameworks       = 'AVFoundation', 'AudioToolbox', 'Accelerate', 'PhotosUI', 'UniformTypeIdentifiers', 'AppTrackingTransparency', 'StoreKit', 'DeviceCheck'
  s.vendored_frameworks = 'Frameworks/lame.xcframework', 'Frameworks/vorbis.xcframework'
  # drift's sqlite3 package resolves SQLite from the process on iOS; this links the system library.
  s.libraries        = 'sqlite3'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version    = '5.0'
  s.resource_bundles = { 'tunely_engine_privacy' => ['Resources/PrivacyInfo.xcprivacy'] }
end
