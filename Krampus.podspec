Pod::Spec.new do |s|
  s.name             = 'Krampus'
  s.version          = '0.1.0'
  s.summary          = 'Add authorization to the web requests made with the resource based network lib Santa'

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/kurzdigital/Krampus'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Christian Braun' => 'christian.braun@kurzdigital.com' }
  s.source           = { :git => 'https://github.com/kurzdigital/krampus.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'Krampus/Classes/**/*'
  
  # s.resource_bundles = {
  #   'Krampus' => ['Krampus/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
   s.dependency 'Santa', '~> 0.1'
end
