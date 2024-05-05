Pod::Spec.new do |spec|
  spec.name = 'EssentialFeed'
  spec.version = '1.0.0'
  spec.license = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.summary = 'Essential Feed platform agnostic module'
  spec.homepage = 'https://github.com/sharaev-vl/EssentialDeveloper-EssentialProject'
  spec.authors = { 'Vlad Sharaev' => 'sharaev.vl.vl@gmail.com' }
  spec.source = { :git => 'https://github.com/sharaev-vl/EssentialDeveloper-EssentialProject.git', :branch => 'main' }
  spec.source_files = 'EssentialFeed/EssentialFeed/**/**/**/**/*.swift'
  spec.resources = [
    'EssentialFeed/EssentialFeed/Feed/Cache/Infrastructure/CoreData/FeedStore.xcdatamodeld',
    'EssentialFeed/EssentialFeed/Presentation/*.lproj'
  ]
  spec.swift_versions = ['5']
  spec.ios.deployment_target = '17.0'
  spec.osx.deployment_target = '12.4'
  spec.framework = 'CoreData'
end