require 'formula'

def build_clang?; ARGV.include? '--with-clang'; end
def build_all_targets?; ARGV.include? '--all-targets'; end
def build_analyzer?; ARGV.include? '--analyzer'; end
def build_rtti?; ARGV.include? '--rtti'; end
def build_jit?; ARGV.include? '--jit'; end

class Clang < Formula
  homepage  'http://llvm.org/'
  url       'http://llvm.org/releases/3.1/clang-3.1.src.tar.gz'
  md5       ''

  head      'http://llvm.org/git/clang.git'
end

class Llvm < Formula
  homepage  'http://llvm.org/'
  url       'http://llvm.org/releases/3.1/llvm-3.1.src.tar.gz'
  md5       '16eaa7679f84113f65b12760fdfe4ee1'

  head      'http://llvm.org/git/llvm.git'

  def options
    [['--with-clang', 'Build clang'],
     ['--analyzer', 'Build clang analyzer'],
     ['--all-targets', 'Build all target backends'],
     ['--rtti', 'Build with RTTI information'],
     ['--jit', 'Build with Just In Time (JIT) compiler functionality']]
  end

  def install
    Clang.new("clang").brew { clang_dir.install Dir['*'] } if build_clang? or build_analyzer?

    ENV['REQUIRES_RTTI'] = '1' if build_rtti?

    configure_options = [
      "--prefix=#{prefix}",
      "--enable-optimized",
      "--enable-shared",
      "--diable-assertions",
      # As of LLVM 3.0, the only bindings offered are for OCaml and attempting
      # to build these when Homebrew's OCaml is installed results in errors.
      #
      # See issue #8947 for details.
      "--enable-bindings=none"
    ]

    if build_all_targets?
      configure_options << "--enable-targets=all"
    else
      configure_options << "--enable-targets=host-only"
    end

    configure_options << "--enable-jit" if build_jit?

    system "./configure", *configure_options

    system "make" # separate steps required, otherwise the build fails
    system "make install"

    cd clang_dir do
      system "make install"
      bin.install 'tools/scan-build/set-xcode-analyzer'
    end if build_clang? or build_analyzer?

    cd clang_dir do
      bin.install 'tools/scan-build/scan-build'
      bin.install 'tools/scan-build/ccc-analyzer'
      bin.install 'tools/scan-build/c++-analyzer'
      bin.install 'tools/scan-build/sorttable.js'
      bin.install 'tools/scan-build/scanview.css'

      bin.install 'tools/scan-view/scan-view'
      bin.install 'tools/scan-view/ScanView.py'
      bin.install 'tools/scan-view/Reporter.py'
      bin.install 'tools/scan-view/startfile.py'
      bin.install 'tools/scan-view/Resources'
    end if build_analyzer?
  end

  def test
    system "#{bin}/llvm-config", "--version"
  end

  def caveats; <<-EOS.undent
    If you already have LLVM installed, then "brew upgrade llvm" might not work.
    Instead, try:
        brew rm llvm && brew install llvm
    EOS
  end

  def clang_dir
    buildpath/'tools/clang'
  end
end
