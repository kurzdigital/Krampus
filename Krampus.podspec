Pod::Spec.new do |s|
  s.name             = 'Krampus'
  s.version          = '0.4.2'
  s.summary          = 'Add authorization to the web requests made with the resource based network lib Santa. Currently supports Keycloak'

  s.description      = <<-DESC
  Provides an authorization plugin for the resource based networking lib Santa. Currently supported are the basic operations for Keycloak. These are login with
  auth code or username and password aswell als logout and refreshing access tokens. The tokens are stored safely within the users keychain.
                       DESC

  s.homepage         = 'https://github.com/kurzdigital/Krampus'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Christian Braun' => 'christian.braun@kurzdigital.com' }
  s.source           = { :git => 'https://github.com/kurzdigital/krampus.git', :tag => s.version.to_s }

  s.swift_version = "5.0"
  s.ios.deployment_target = '9.0'

  s.source_files = 'Krampus/Classes/**/*'
  
  s.dependency 'Santa', '~> 0.5'
end
