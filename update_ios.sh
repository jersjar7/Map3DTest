#!/bin/bash

# Navigate to project directory
cd "$(dirname "$0")"

echo "Updating iOS deployment target to 14.0..."

# Update Podfile
cat > ios/Podfile << 'EOL'
platform :ios, '14.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # Add the Google Maps pod here
  pod 'GoogleMaps'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    # Set minimum iOS version to 14.0 for all targets
    target.build_configurations.each do |config|
      # Set deployment target for iOS
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      
      # Location permissions descriptions
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_LOCATION=1',
      ]
      
      # This removes the need to have BITCODE support
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
EOL

# Update project.pbxproj
echo "Updating project.pbxproj..."
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 12.0;/IPHONEOS_DEPLOYMENT_TARGET = 14.0;/g' ios/Runner.xcodeproj/project.pbxproj
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 13.4;/IPHONEOS_DEPLOYMENT_TARGET = 14.0;/g' ios/Runner.xcodeproj/project.pbxproj
sed -i '' 's/IPHONEOS_DEPLOYMENT_TARGET = 16.6;/IPHONEOS_DEPLOYMENT_TARGET = 14.0;/g' ios/Runner.xcodeproj/project.pbxproj

# Also update AppFrameworkInfo.plist
echo "Updating AppFrameworkInfo.plist..."
sed -i '' 's/<string>12.0<\/string>/<string>14.0<\/string>/g' ios/Flutter/AppFrameworkInfo.plist

# Clean up
echo "Cleaning up..."
rm -rf ios/Pods ios/Podfile.lock
rm -rf build/ .dart_tool/

# Install pods
echo "Installing pods..."
cd ios
pod install --repo-update
cd ..

# Get packages
echo "Getting packages..."
flutter pub get

echo "Setup completed. Now try running: flutter run"