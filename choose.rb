class Choose < Formula
  homepage "https://github.com/sdegutis/choose"
  url "https://github.com/sdegutis/choose/archive/1.0.tar.gz"
  sha1 "7c175035a9fef90f1eee38867cf3762d52641f9f"

  head "https://github.com/sdegutis/choose.git"

  depends_on :xcode => :build

  def install
    xcodebuild "SDKROOT=", "SYMROOT=build"
    bin.install "build/Release/choose"
  end
end
