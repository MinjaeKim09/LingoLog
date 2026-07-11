require 'xcodeproj'
project_path = 'LingoLog.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'LingoLog' }

# 1. Disable Generate Info.plist File
target.build_configurations.each do |config|
  config.build_settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  config.build_settings['INFOPLIST_FILE'] = 'Info.plist'
  # Delete the auto-generated ones that conflict
  config.build_settings.delete('INFOPLIST_KEY_UIApplicationSceneManifest_Generation')
  config.build_settings.delete('INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents')
  config.build_settings.delete('INFOPLIST_KEY_UILaunchScreen_Generation')
  config.build_settings.delete('INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad')
  config.build_settings.delete('INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone')
  config.build_settings.delete('INFOPLIST_KEY_CFBundleURLTypes')
end

project.save
puts "Successfully updated project build settings!"
