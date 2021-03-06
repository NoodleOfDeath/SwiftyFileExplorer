#
# Be sure to run `pod lib lint SwiftyFileExplorer.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'SwiftyFileExplorer'
    s.version          = '1.0'
    s.summary          = 'Lightweight framework that provides a FileExplorer UI for viewing and accessing filesystems.'

    # This description is used to generate tags and improve search results.
    #   * Think: What does it do? Why did you write it? What is the focus?
    #   * Try to keep it short, snappy and to the point.
    #   * Write the description between the DESC delimiters below.
    #   * Finally, don't worry about the indent, CocoaPods strips it!

    s.description      = <<-DESC
    Lightweight framework that provides a FileExplorer UI for viewing and accessing filesystems.
    DESC

    s.homepage         = 'https://github.com/NoodleOfDeath/SwiftyFileExplorer'
    # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'NoodleOfDeath' => 'git@noodleofdeath.com' }
    s.source           = { :git => 'https://github.com/NoodleOfDeath/SwiftyFileExplorer.git', :tag => s.version.to_s }
    # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

    s.ios.deployment_target = '9.0'

    s.source_files = 'SwiftyFileExplorer/Classes/**/*'

    s.resource_bundles = {
        'SwiftyFileExplorer' => ['SwiftyFileExplorer/Assets/**/*.theme']
    }

    s.public_header_files = 'Pod/Classes/**/*.h'
    # s.frameworks = 'UIKit', 'MapKit'
    s.dependency 'SnapKit', '~> 4.2'
    s.dependency 'SwiftyFileSystem', '~> 1.0'
end
