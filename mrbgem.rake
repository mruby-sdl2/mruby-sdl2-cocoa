MRuby::Gem::Specification.new('mruby-sdl2-cocoa') do |spec|
  spec.license = 'MIT'
  spec.authors = 'kabies'
  spec.add_dependency('mruby-sdl2')

  spec.linker.flags << '-framework Cocoa'
end