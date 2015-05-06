Pod::Spec.new do |s|

  s.name         = "hashids"
  s.version      = "0.0.1"
  s.license      = "MIT"
  s.homepage     = "http://hashids.org"
  s.summary      = "Small open-source library that generates short, unique, non-sequential ids from numbers."
  s.author       = { "Mateusz Malczak" => "mateusz@malczak.info" }
  s.source       = { :git => "https://github.com/malczak/hashids.git", :commit => "c5f99e68343768093fdea4301045480384be5f8c" }

  s.platform     = :ios, "8.0"

  s.source_files  = "*.swift"
  s.exclude_files = "*Tests.swift"

  s.requires_arc = true
end
