#
# Be sure to run `pod lib lint WLQRCodeScaning.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'WLQRCodeScaning'
  s.version          = '0.1.2'
  s.summary          = 'QRCode Scanning'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/Nomeqc/WLQRCodeScanning'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'nomeqc@gmail.com' => 'xie5405@163.com' }
  s.source           = { :git => 'https://github.com/Nomeqc/WLQRCodeScanning.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'
  s.prefix_header_file = 'WLQRCodeScaning/pch/WLQRCodeScaning-Prefix.pch'
  s.source_files = 'WLQRCodeScaning/Classes/**/*'
  s.public_header_files = 'WLQRCodeScaning/Classes/**/*.h'
  s.resource_bundles = {
    'WLQRCodeScanning' => ['WLQRCodeScaning/Resources/**/*.*']
  }
  s.dependency 'Masonry'
  s.dependency 'pop'
  s.dependency 'ChameleonFramework'
end
