class Tile38 < Formula
  desc "In-memory geolocation data store, spatial index, and realtime geofence"
  homepage "https://tile38.com/"
  url "https://github.com/tidwall/tile38.git",
      tag:      "1.26.0",
      revision: "26f9678ba058fc3ff325244a21928fa6faf64bee"
  license "MIT"
  head "https://github.com/tidwall/tile38.git", branch: "master"

  bottle do
    sha256 cellar: :any_skip_relocation, arm64_big_sur: "bc13235adfa68d851134f23019f9bf7a0469f42c1347548ec77fc6afdf16c653"
    sha256 cellar: :any_skip_relocation, big_sur:       "d8985f5f1746a6c2fc64a36adb6b1d3fc54d2584f04222a598010d16f7ff7a2a"
    sha256 cellar: :any_skip_relocation, catalina:      "ed03a353784f0b9a35de2660c955fd7baded73e6d3916a8f4fea232a5a5767e6"
    sha256 cellar: :any_skip_relocation, mojave:        "e39659e21794a852634f53fe26733d8c73599ffdeea77f811d76e0fe483191ad"
    sha256 cellar: :any_skip_relocation, x86_64_linux:  "d69af284cda466f78e9fe1f258bf847b75d88dccea4c847b4128263e0eb5ad92"
  end

  depends_on "go" => :build

  def datadir
    var/"tile38/data"
  end

  def install
    ldflags = %W[
      -s -w
      -X github.com/tidwall/tile38/core.Version=#{version}
      -X github.com/tidwall/tile38/core.GitSHA=#{Utils.git_short_head}
    ].join(" ")

    system "go", "build", *std_go_args(ldflags: ldflags), "-o", bin/"tile38-server", "./cmd/tile38-server"
    system "go", "build", *std_go_args(ldflags: ldflags), "-o", bin/"tile38-cli", "./cmd/tile38-cli"
  end

  def post_install
    # Make sure the data directory exists
    datadir.mkpath
  end

  def caveats
    <<~EOS
      To connect: tile38-cli
    EOS
  end

  service do
    run [opt_bin/"tile38-server", "-d", var/"tile38/data"]
    keep_alive true
    working_dir var
    log_path var/"log/tile38.log"
    error_log_path var/"log/tile38.log"
  end

  test do
    port = free_port
    pid = fork do
      exec "#{bin}/tile38-server", "-q", "-p", port.to_s
    end
    sleep 2
    # remove `$408` in the first line output
    json_output = shell_output("#{bin}/tile38-cli -p #{port} server")
    tile38_server = JSON.parse(json_output)

    assert_equal tile38_server["ok"], true
    assert_predicate testpath/"data", :exist?
  ensure
    Process.kill("HUP", pid)
  end
end
