#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint beacon_broadcaster.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'beacon_broadcaster'
  s.version          = '0.2.2'
  s.summary          = 'Flutter plugin for broadcasting iBeacon packets.'
  s.description      = <<-DESC
Flutter plugin for broadcasting iBeacon packets on Android and iOS.
                       DESC
  s.homepage         = 'https://pub.dev/packages/beacon_broadcaster'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'beacon_broadcaster' => 'maintainers@pub.dev' }
  s.source           = { :path => '.' }
  s.source_files = 'beacon_broadcaster/Sources/beacon_broadcaster/**/*.swift'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  s.resource_bundles = { 'beacon_broadcaster_privacy' => ['beacon_broadcaster/Sources/beacon_broadcaster/PrivacyInfo.xcprivacy'] }
end
