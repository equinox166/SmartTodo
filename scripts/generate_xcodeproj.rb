#!/usr/bin/env ruby
# Generates SmartTodo.xcodeproj from the source tree using the xcodeproj gem.
# Run with: ruby scripts/generate_xcodeproj.rb

require 'xcodeproj'
require 'fileutils'

ROOT = File.expand_path('..', __dir__)
PROJECT_PATH = File.join(ROOT, 'SmartTodo.xcodeproj')
APP_NAME = 'SmartTodo'
BUNDLE_ID = 'com.smarttodo.app'
DEPLOYMENT_TARGET = '17.0'
SWIFT_VERSION = '5.9'

FileUtils.rm_rf(PROJECT_PATH)
project = Xcodeproj::Project.new(PROJECT_PATH)
project.build_configurations.each do |c|
  c.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  c.build_settings['SWIFT_VERSION'] = SWIFT_VERSION
  c.build_settings['SDKROOT'] = 'iphoneos'
  c.build_settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  c.build_settings['ALWAYS_SEARCH_USER_PATHS'] = 'NO'
  c.build_settings['CLANG_ANALYZER_NONNULL'] = 'YES'
  c.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
  c.build_settings['CLANG_ENABLE_OBJC_ARC'] = 'YES'
  c.build_settings['ENABLE_STRICT_OBJC_MSGSEND'] = 'YES'
  c.build_settings['GCC_NO_COMMON_BLOCKS'] = 'YES'
end

target = project.new_target(:application, APP_NAME, :ios, DEPLOYMENT_TARGET)

# Per-target build settings
target.build_configurations.each do |c|
  settings = c.build_settings
  settings['ASSETCATALOG_COMPILER_APPICON_NAME'] = 'AppIcon'
  settings['ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME'] = 'AccentColor'
  settings['CURRENT_PROJECT_VERSION'] = '1'
  settings['MARKETING_VERSION'] = '1.0'
  settings['DEVELOPMENT_ASSET_PATHS'] = '"SmartTodo/Preview Content"'
  settings['ENABLE_PREVIEWS'] = 'YES'
  settings['GENERATE_INFOPLIST_FILE'] = 'NO'
  settings['INFOPLIST_FILE'] = 'SmartTodo/Resources/Info.plist'
  settings['LD_RUNPATH_SEARCH_PATHS'] = ['$(inherited)', '@executable_path/Frameworks']
  settings['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
  settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
  settings['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
  settings['TARGETED_DEVICE_FAMILY'] = '1,2'
  settings['SWIFT_VERSION'] = SWIFT_VERSION
  settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOYMENT_TARGET
  settings['CODE_SIGN_STYLE'] = 'Automatic'
end

# File groups mirroring folder structure on disk.
main_group = project.new_group(APP_NAME, APP_NAME)

def add_sources(project, target, group, dir_abs, dir_rel)
  Dir.children(dir_abs).sort.each do |entry|
    full = File.join(dir_abs, entry)
    relative = File.join(dir_rel, entry)
    if File.directory?(full)
      # Treat .xcassets and preview content as folder references handled below.
      if entry.end_with?('.xcassets')
        file_ref = group.new_reference(relative)
        file_ref.last_known_file_type = 'folder.assetcatalog'
        target.resources_build_phase.add_file_reference(file_ref)
        next
      end
      sub = group.new_group(entry, entry)
      add_sources(project, target, sub, full, relative)
    else
      file_ref = group.new_reference(relative)
      case entry
      when /\.swift\z/
        target.source_build_phase.add_file_reference(file_ref)
      when 'Info.plist'
        # Referenced via INFOPLIST_FILE build setting; no build phase.
      when /\.plist\z/, /\.json\z/, /\.strings\z/
        target.resources_build_phase.add_file_reference(file_ref)
      end
    end
  end
end

add_sources(project, target, main_group, File.join(ROOT, APP_NAME), APP_NAME)

project.save
puts "Generated #{PROJECT_PATH}"
