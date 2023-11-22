require 'mkmf'
require 'fileutils'

BASEDIR     = File.expand_path(File.dirname(__FILE__))
BUNDLE      = Dir.glob("#{BASEDIR}/pHash-*.tar.gz").first
BUNDLE_PATH = BUNDLE.gsub(".tar.gz", "")
$CFLAGS     = " -x c++ #{ENV["CFLAGS"]}"
$CFLAGS    += " -fdeclspec" if RUBY_PLATFORM =~ /darwin/
$includes   = " -I#{BASEDIR}/include"
$libraries  = " -L#{BASEDIR}/lib -L/usr/local/lib"
$LIBPATH    = ["#{BASEDIR}/lib"]
$CFLAGS     = "#{$includes} #{$libraries} #{$CFLAGS}"
$LDFLAGS    = "#{$libraries} #{$LDFLAGS}"
$CXXFLAGS   = ' -pthread'

Dir.chdir(BASEDIR) do
  if File.exist?("lib")
    puts "pHash already built; run 'rake clean' first if you need to rebuild."
  else
    puts(cmd = "tar -xzf #{BUNDLE} 2>&1")
    raise "'#{cmd}' failed" unless system(cmd)

    puts "patching pHash sources for PNG alpha channel support"
    puts(cmd = "patch -d pHash-0.9.6 -p1 < #{File.join 'patches', 'png_alpha.diff'}")
    raise "'#{cmd}' failed" unless system(cmd)

    puts "updating config.{guess,sub} to support newer architectures"
    FileUtils.mv File.join('patches', 'config.sub'  ), BUNDLE_PATH, force: true
    FileUtils.mv File.join('patches', 'config.guess'), BUNDLE_PATH, force: true

    puts "updating CImg header version"
    FileUtils.mv 'patches/CImg.h', BUNDLE_PATH, force: true

    Dir.chdir(BUNDLE_PATH) do
      puts(cmd = "env CXXFLAGS='#{$CXXFLAGS}' CFLAGS='#{$CFLAGS}' LDFLAGS='#{$LDFLAGS}' ./configure --prefix=#{BASEDIR} --disable-audio-hash --disable-video-hash --disable-shared --with-pic 2>&1")
      raise "'#{cmd}' failed" unless system(cmd)

      puts(cmd = "make || true 2>&1")
      raise "'#{cmd}' failed" unless system(cmd)

      puts(cmd = "make install || true 2>&1")
      raise "'#{cmd}' failed" unless system(cmd)

      FileUtils.mv %w{ CImg.h pHash-config.h }, '../include', force: true
    end

    FileUtils.rm_rf BUNDLE_PATH unless ENV['DEBUG'] or ENV['DEV']
  end

  Dir.chdir('lib') do
    FileUtils.mv 'libpHash.a' , 'libpHash_gem.a' , force: true
    FileUtils.mv 'libpHash.la', 'libpHash_gem.la', force: true
  end # Dir.chdir /lib

  $LIBS = " -lpthread -lpHash_gem -lstdc++ -ljpeg -lpng -lm"
end # Dir.chdir /

have_header 'sqlite3ext.h'

create_makefile 'phashion_ext'
