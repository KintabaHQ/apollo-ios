Pod::Spec.new do |s|
  s.name         = 'Apollo'
  s.version      = '0.48.1'
  s.author       = 'Meteor Development Group'
  s.homepage     = 'https://github.com/apollographql/apollo-ios'
  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.summary      = "A GraphQL client for iOS, written in Swift."

  s.source       = { :git => 'https://github.com/KintabaHQ/apollo-ios.git', :tag => s.version }

  s.requires_arc = true

  s.swift_version = '5.0'

  s.default_subspecs = 'Core'

  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.14'
  s.tvos.deployment_target = '12.0'
  s.watchos.deployment_target = '5.0'

  s.subspec 'Core' do |ss|
    ss.source_files = 'Sources/Apollo/*.swift','Sources/ApolloUtils/*.swift','Sources/ApolloAPI/*.swift'
    ss.exclude_files = 'Sources/ApolloAPI/CodegenV1/*.swift'
    ss.preserve_paths = [
      'scripts/run-bundled-codegen.sh',
    ]
  end

  # Apollo provides exactly one persistent cache out-of-the-box, as a reasonable default choice for
  # those who require cache persistence. Third-party caches may use different storage mechanisms.
  s.subspec 'SQLite' do |ss|
    ss.source_files = 'Sources/ApolloSQLite/*.swift'
    ss.dependency 'Apollo/Core'
    ss.dependency 'SQLite.swift', '~>0.12.2'
  end

  # Websocket and subscription support based on Starscream
  s.subspec 'WebSocket' do |ss|
    ss.source_files = 'Sources/ApolloWebSocket/**/*.swift'
    ss.dependency 'Apollo/Core'
  end

end
