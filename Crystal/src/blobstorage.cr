require "./sha512_256.cr"

module ServerBenchmark
  module BlobStorage
    extend self

    @@dir = Path[Dir.tempdir, "/server-benchmark-crystal/"]

    def init
      Dir.mkdir_p @@dir
    end

    def clean
      rm_r @@dir
    end

    def reset
      clean
      init
    end

    private def rm_r(path)
      if Dir.exists?(path) && !File.symlink?(path)
        Dir.each_child(path) do |entry|
          src = File.join(path, entry)
          rm_r(src)
        end
        Dir.delete(path)
      else
        File.delete(path)
      end
    end

    def upload(socket, key, size)
      hash = Digest::SHA512_256.new
      buf = Bytes.new(1024)
      path = Path[@@dir, key]

      File.open path, "w" do |f|
        socket << "READY\n"
        while (size > 1024)
          amount = socket.read buf
          return "File transfer aborted: Client disconnected" if amount != 1024
          f.write buf
          hash.update buf
          size -= 1024
        end

        buf = Bytes.new(size)
        amount = socket.read buf
        return "File transfer aborted: Client disconnected" if amount != size
        f.write buf
        hash.update buf
      end

      socket.puts hash.final.hexstring
      response = socket.gets
      return if response.nil?

      if response == "ERROR"
        File.delete path
      elsif response != "OK"
        puts "[Crystal] unexpected client response to UPLOAD #{response}"
      end
    end

    def download(socket, key)
      hash = Digest::SHA512_256.new
      buf = Bytes.new(1024)
      path = Path[@@dir, key]

      unless File.exists? path
        socket.puts "not found"
        return
      end

      socket.puts File.size path

      return if socket.gets != "READY"

      File.open path, "r" do |f|
        size = f.size

        while (size > 1024)
          amount = f.read buf
          socket.write buf
          hash.update buf
          size -= 1024
        end

        buf = Bytes.new size
        f.read buf
        socket.write buf
        hash.update buf
      end

      socket.puts socket.gets == hash.final.hexstring ? "OK" : "ERROR"
    end

    def remove(key)
      File.delete Path[@@dir, key]
    end
  end
end
