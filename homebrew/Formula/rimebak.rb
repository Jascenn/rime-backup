class Rimebak < Formula
  desc "Rime input method configuration backup and restore tool"
  homepage "https://github.com/Jascenn/rime-backup"
  url "https://github.com/Jascenn/rime-backup/archive/refs/tags/v2.1.0.tar.gz"
  sha256 "REPLACE_WITH_ACTUAL_SHA256"
  license "MIT"
  head "https://github.com/Jascenn/rime-backup.git", branch: "main"

  depends_on "rsync"

  def install
    bin.install "rimebak.sh" => "rimebak"
  end

  def caveats
    <<~EOS
      RimeBak 已安装！

      首次使用请运行:
        rimebak setup

      常用命令:
        rimebak              进入交互式菜单
        rimebak list         列出所有备份
        rimebak restore 1    恢复指定备份
        rimebak git sync     同步到 GitHub
        rimebak --help       查看帮助
    EOS
  end

  test do
    assert_match "RimeBak v#{version}", shell_output("#{bin}/rimebak --version")
  end
end
