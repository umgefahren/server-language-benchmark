require "openssl"

# Implements the SHA512/256 digest algorithm.
class Digest::SHA512_256 < ::OpenSSL::Digest
  extend ClassMethods

  def initialize
    super("SHA512-256")
  end

  protected def initialize(ctx : LibCrypto::EVP_MD_CTX)
    super("SHA512-256", ctx)
  end

  def dup
    self.class.new(dup_ctx)
  end
end
