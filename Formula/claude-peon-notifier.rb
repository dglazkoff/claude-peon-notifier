class ClaudePeonNotifier < Formula
  desc "Warcraft peon voice + icon notifications for Claude Code hooks (macOS)"
  homepage "https://github.com/dglazkoff/claude-peon-notifier"
  # After you tag a release, set url + sha256:
  #   url "https://github.com/dglazkoff/claude-peon-notifier/archive/refs/tags/v0.1.0.tar.gz"
  #   shasum -a 256 the downloaded tarball  ->  paste below
  url "https://github.com/dglazkoff/claude-peon-notifier/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "REPLACE_WITH_TARBALL_SHA256"
  license "MIT"

  depends_on :macos

  def install
    libexec.install "bin", "share"
    libexec.install "assets" if Dir.exist?("assets")
    (bin/"claude-peon").write <<~SH
      #!/bin/bash
      exec "#{libexec}/bin/claude-peon" "$@"
    SH
  end

  def caveats
    <<~EOS
      Run the one-time setup:
        claude-peon install

      Then enable banners for "Peon" in
        System Settings → Notifications → Peon (Allow + Banners/Alerts)

      Drop your assets into ~/.claude/peon:
        peon.png (or .jpg), done.mp3, wait.mp3
      and run:  claude-peon build
    EOS
  end

  test do
    assert_match "claude-peon", shell_output("#{bin}/claude-peon help")
  end
end
