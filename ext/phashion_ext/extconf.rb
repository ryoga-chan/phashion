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
    puts(cmd = "tar xzf #{BUNDLE} 2>&1")
    raise "'#{cmd}' failed" unless system(cmd)

    puts "patching pHash sources for PNG alpha channel support"
    puts(cmd = "patch -d pHash-0.9.6 -p1 < patches/png_alpha.diff")
    raise "'#{cmd}' failed" unless system(cmd)

    puts "updating config.{guess,sub} to support newer architectures"
    FileUtils.cp_f 'patches/config.sub'  , BASEDIR
    FileUtils.cp_f 'patches/config.guess', BASEDIR

    Dir.chdir(BUNDLE_PATH) do
      puts(cmd = "env CXXFLAGS='#{$CXXFLAGS}' CFLAGS='#{$CFLAGS}' LDFLAGS='#{$LDFLAGS}' ./configure --prefix=#{BASEDIR} --disable-audio-hash --disable-video-hash --disable-shared --with-pic 2>&1")
      raise "'#{cmd}' failed" unless system(cmd)

      puts(cmd = "make || true 2>&1")
      raise "'#{cmd}' failed" unless system(cmd)

      puts(cmd = "make install || true 2>&1")
      raise "'#{cmd}' failed" unless system(cmd)

      puts(cmd = "mv CImg.h ../include 2>&1")
      raise "'#{cmd}' failed" unless system(cmd)
    end

    system("rm -rf #{BUNDLE_PATH}") unless ENV['DEBUG'] or ENV['DEV']
  end

  Dir.chdir("#{BASEDIR}/lib") do
    system("cp -f libpHash.a  libpHash_gem.a")
    system("cp -f libpHash.la libpHash_gem.la")
  end # Dir.chdir /lib

  $LIBS = " -lpthread -lpHash_gem -lstdc++ -ljpeg -lpng -lm"
end # Dir.chdir /

have_header 'sqlite3ext.h'

create_makefile 'phashion_ext'
