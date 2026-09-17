class AgyStatusline < Formula
  desc "Fast, beautiful 2-line status line for Google Antigravity CLI (agy)"
  homepage "https://github.com/chahine/agy-statusline"
  url "https://github.com/chahine/agy-statusline.git", branch: "main"
  version "0.1.0"
  license "MIT"

  depends_on "jq"

  def install
    bin.install "bin/statusline.sh" => "agy-statusline"
    bin.install "bin/install.sh" => "agy-statusline-setup"
    bin.install "bin/uninstall.sh" => "agy-statusline-uninstall"
  end

  def caveats
    <<~EOS
      To activate agy-statusline in Google Antigravity CLI (agy), run:
        agy-statusline-setup

      Or manually configure ~/.gemini/antigravity-cli/settings.json:
        {
          "statusLine": {
            "type": "command",
            "command": "agy-statusline",
            "enabled": true
          }
        }
    EOS
  end

  test do
    mock_input = '{"model":{"id":"gemini-3.8-flash-med","display_name":"3.8 Flash Med"},"plan_tier":"Pro","agent_state":"idle","cwd":"/workspace/test","terminal_width":120}'
    output = pipe_output("#{bin}/agy-statusline", mock_input)
    assert_match "3.8 Flash Med", output
  end
end
