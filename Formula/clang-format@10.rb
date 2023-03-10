class ClangFormatAT10 < Formula
  desc "Formatting tools for C, C++, Obj-C, Java, JavaScript, TypeScript"
  homepage "https://clang.llvm.org/docs/ClangFormat.html"
  # The LLVM Project is under the Apache License v2.0 with LLVM Exceptions
  license "Apache-2.0"
  version_scheme 1
  head "https://github.com/llvm/llvm-project.git"

  stable do
    url "https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.1/llvm-10.0.1.src.tar.xz"
    sha256 "c5d8e30b57cbded7128d78e5e8dad811bff97a8d471896812f57fa99ee82cdf3"

    resource "clang" do
      url "https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.1/clang-10.0.1.src.tar.xz"
      sha256 "f99afc382b88e622c689b6d96cadfa6241ef55dca90e87fc170352e12ddb2b24"
    end

    resource "libcxx" do
      url "https://github.com/llvm/llvm-project/releases/download/llvmorg-10.0.1/libcxx-10.0.1.src.tar.xz"
      sha256 "def674535f22f83131353b3c382ccebfef4ba6a35c488bdb76f10b68b25be86c"
    end
  end

  livecheck do
    url "https://github.com/llvm/llvm-project/releases/latest"
    regex(%r{href=.*?/tag/llvmorg[._-]v?(\d+(?:\.\d+)+)}i)
  end

  depends_on "cmake" => :build
  depends_on "ninja" => :build

  uses_from_macos "libxml2"
  uses_from_macos "ncurses"
  uses_from_macos "zlib"

  def install
    if build.head?
      ln_s buildpath/"libcxx", buildpath/"llvm/projects/libcxx"
      ln_s buildpath/"clang", buildpath/"llvm/tools/clang"
    else
      (buildpath/"projects/libcxx").install resource("libcxx")
      (buildpath/"tools/clang").install resource("clang")
    end

    llvmpath = build.head? ? buildpath/"llvm" : buildpath

    mkdir llvmpath/"build" do
      args = std_cmake_args
      args << "-DLLVM_ENABLE_LIBCXX=ON"
      args << ".."
      system "cmake", "-G", "Ninja", *args
      system "ninja", "clang-format"
    end

    bin.install llvmpath/"build/bin/clang-format" => "clang-format-10"
    bin.install llvmpath/"tools/clang/tools/clang-format/git-clang-format" => "git-clang-format-10"
    (share/"clang-10").install Dir[llvmpath/"tools/clang/tools/clang-format/clang-format*"]
  end

  test do
    # NB: below C code is messily formatted on purpose.
    (testpath/"test.c").write <<~EOS
      int         main(char *args) { \n   \t printf("hello"); }
    EOS

    assert_equal "int main(char *args) { printf(\"hello\"); }\n",
        shell_output("#{bin}/clang-format-10 -style=Google test.c")
  end
end
