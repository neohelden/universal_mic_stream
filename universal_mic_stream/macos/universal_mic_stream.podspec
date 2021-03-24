#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint universal_mic_stream.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'universal_mic_stream'
  s.version          = '0.1.0'
  s.summary          = 'universal_mic_stream enables you to access the microphone as a stream of data across different platforms and devices.'
  s.description      = <<-DESC
A new flutter plugin project.
                       DESC
  s.homepage         = 'https://neohelden.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Neohelden GmbH' => 'hello@neohelden.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'FlutterMacOS'

  s.platform = :osx, '10.11'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'
end
