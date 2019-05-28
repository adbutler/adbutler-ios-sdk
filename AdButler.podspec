Pod::Spec.new do |s|
  s.name = 'AdButler'
  s.version = '1.0.3'
  s.license = 'Apache 2.0'
  s.summary = 'iOS SDK for the AdButler API'
  s.homepage = 'https://github.com/adbutler/adbutler-ios-sdk'
  s.authors = { 'SparkLIT' => 'hello@sparklit.com' }
  s.source = { :git => 'https://github.com/adbutler/adbutler-ios-sdk.git', :tag => s.version }
  s.source_files = 'AdButler/AdButler/*.swift'
  s.platform     = :ios, '10.2'
  s.frameworks = 'Foundation'
  s.swift_version = '5'
end
