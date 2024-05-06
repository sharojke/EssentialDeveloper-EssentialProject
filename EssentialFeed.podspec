Pod::Spec.new do |spec|
  spec.name = 'EssentialFeed'
  spec.version = '1.0.0'
  spec.license = { :type => 'MIT', :file => 'LICENSE.md' }
  spec.summary = 'Essential Feed platform agnostic module'
  spec.homepage = 'https://github.com/sharaev-vl/EssentialDeveloper-EssentialProject'
  spec.authors = { 'Vlad Sharaev' => 'sharaev.vl.vl@gmail.com' }
  spec.source = { :git => 'https://github.com/sharaev-vl/EssentialDeveloper-EssentialProject.git', :branch => 'main' }
  spec.swift_versions = ['5']
  spec.ios.deployment_target = '17.0'
  spec.osx.deployment_target = '12.4'

  spec.default_subspecs = :none

  spec.subspec 'FeedFeature' do |ff|
    ff.source_files = 'EssentialFeed/EssentialFeed/Feed/Domain/*.swift'
  end

  spec.subspec 'FeedAPI' do |fa|
    fa.source_files = 'EssentialFeed/EssentialFeed/Feed/API/**/*.swift'
    fa.dependency 'EssentialFeed/FeedFeature'
  end

  spec.subspec 'FeedCache' do |fc|
    fc.source_files = 'EssentialFeed/EssentialFeed/Feed/Cache/*.swift'
    fc.dependency 'EssentialFeed/FeedFeature'
  end

  spec.subspec 'FeedCacheInfrastructure' do |fci|
    fci.source_files = 'EssentialFeed/EssentialFeed/Feed/Cache/Infrastructure/**/*.swift'
    fci.resources = 'EssentialFeed/EssentialFeed/Feed/Cache/Infrastructure/CoreData/FeedStore.xcdatamodeld'
    fci.dependency 'EssentialFeed/FeedCache'
  end

  spec.subspec 'FeedPresentation' do |fp|
    fp.source_files = 'EssentialFeed/EssentialFeed/Feed/Presentation/*.swift'
    fp.dependency 'EssentialFeed/FeedFeature'
  end

//

  spec.subspec 'ImageCommentsFeature' do |icf|
    icf.source_files = 'EssentialFeed/EssentialFeed/Image Comments/Domain/*.swift'
  end

  spec.subspec 'ImageCommentsAPI' do |ica|
    ica.source_files = 'EssentialFeed/EssentialFeed/Image Comments/API/*.swift'
    ica.dependency 'EssentialFeed/ImageCommentsFeature'
  end

  spec.subspec 'ImageCommentsPresentation' do |icp|
    icp.source_files = 'EssentialFeed/EssentialFeed/Image Comments/Presentation/*.swift'
    icp.dependency 'EssentialFeed/ImageCommentsFeature'
  end

//

 spec.subspec 'SharedAPI' do |sa|
    sa.source_files = 'EssentialFeed/EssentialFeed/Shared/API/*.swift'
  end

  spec.subspec 'SharedAPIInfra' do |sai|
    sai.source_files = 'EssentialFeed/EssentialFeed/Shared/API Infra/*.swift'
    sai.dependency 'EssentialFeed/SharedAPI'
  end

  spec.subspec 'SharedPresentation' do |sp|
    sp.source_files = 'EssentialFeed/EssentialFeed/Shared/Presentation/*.swift'
    sp.resources = 'EssentialFeed/EssentialFeed/Shared/Presentation/*.lproj'
  end
end