Pod::Spec.new do |s|

  s.name         = "Hashids-Swift"
  s.version      = "0.3.2"
  s.license      = "MIT"
  s.homepage     = "http://hashids.org/swift/"
  s.summary      = "Small open-source library that generates short, unique, non-sequential ids from numbers."
  s.author       = { "Matt" => "mateusz@malczak.info" }
  s.source       = { :git => "https://github.com/malczak/hashids.git", :tag => s.version.to_s }

  s.source_files = "Sources/hashids/*"

  s.platform     = :ios, "11.0"

  s.requires_arc = true
end
