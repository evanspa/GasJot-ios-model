Pod::Spec.new do |s|
  s.name         = "PEFuelPurchase-Model"
  s.version      = "1.0.109"
  s.license      = "MIT"
  s.summary      = "An iOS static library representing the core logic of the PEFuelPurchase-App application."
  s.author       = { "Paul Evans" => "evansp2@gmail.com" }
  s.homepage     = "https://github.com/evanspa/#{s.name}"
  s.source       = { :git => "https://github.com/evanspa/#{s.name}.git", :tag => "#{s.name}-v#{s.version}" }
  s.platform     = :ios, '8.3'
  s.source_files = '**/*.{h,m}'
  s.public_header_files = '**/*.h'
  s.exclude_files = "**/*Tests/*.*"
  s.requires_arc = true
  s.dependency 'PEObjc-Commons', '~> 1.0.56'
  s.dependency 'PEFuelPurchase-Common', '~> 1.0.8'
  s.dependency 'FMDB', '~> 2.5'
  s.dependency 'PEHateoas-Client', '~> 1.0.6'
  s.dependency 'CocoaLumberjack', '~> 1.9'
  s.dependency 'UICKeyChainStore', '~> 2.0.4'
  s.library = 'sqlite3'
end
