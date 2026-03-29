class ClaudeTallow < Formula
  desc "Status line for Claude Code — shows model, tokens, cache hit rate, and session cost"
  homepage "https://github.com/Devejya/homebrew-tallow"
  url "https://github.com/Devejya/homebrew-tallow/archive/refs/tags/v1.0.5.tar.gz"
  sha256 "ff8aa2f1ec76aabd54f99affc2bd0037148873011c535291f02c8762ff64eb14"
  license "MIT"
  version "1.0.5"

  depends_on "jq"

  def install
    bin.install "bin/claude-tallow"
    (share/"claude-tallow").install "share/statusline-command.sh"
  end

  def caveats
    <<~EOS
      To set up the Claude Code status line, run:
        claude-tallow install

      This will:
        - Copy the status line script to ~/.claude/statusline-command.sh
        - Add the statusLine config to ~/.claude/settings.json

      To remove it:
        claude-tallow uninstall

      To check installation status:
        claude-tallow status
    EOS
  end

  test do
    assert_match "claude-tallow", shell_output("#{bin}/claude-tallow help")
  end
end
