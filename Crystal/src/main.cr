require "socket"

require "./blobstorage.cr"
require "./server.cr"

ServerBenchmark::BlobStorage.init
server = ServerBenchmark::Server.new

Signal::INT.trap do
  ServerBenchmark::BlobStorage.clean
end

Signal::TERM.trap do
  ServerBenchmark::BlobStorage.clean
end

server.start
