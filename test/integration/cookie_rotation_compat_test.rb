require 'test_helper'

class CookieRotationCompatTest < ActionDispatch::IntegrationTest
  def old_key_generator
    ActiveSupport::KeyGenerator.new(
      Rails.application.secret_key_base,
      iterations: 1000,
      hash_digest_class: OpenSSL::Digest::SHA1
    )
  end

  def new_key_generator
    ActiveSupport::KeyGenerator.new(
      Rails.application.secret_key_base,
      iterations: 1000,
      hash_digest_class: OpenSSL::Digest::SHA256
    )
  end

  test 'legacy signed payload can be verified by rotated verifier' do
    signed_cookie_salt = Rails.application.config.action_dispatch.signed_cookie_salt

    old_secret = old_key_generator.generate_key(signed_cookie_salt)
    new_secret = new_key_generator.generate_key(signed_cookie_salt)

    old_verifier = ActiveSupport::MessageVerifier.new(old_secret, digest: 'SHA1')
    new_verifier = ActiveSupport::MessageVerifier.new(new_secret, digest: 'SHA1')
    new_verifier.rotate(old_secret)

    legacy_token = old_verifier.generate('legacy-signed-value')

    assert_equal 'legacy-signed-value', new_verifier.verify(legacy_token)
  end

  test 'legacy encrypted payload can be decrypted by rotated encryptor' do
    encrypted_cookie_salt = Rails.application.config.action_dispatch.encrypted_cookie_salt
    encrypted_signed_cookie_salt = Rails.application.config.action_dispatch.encrypted_signed_cookie_salt
    key_len = ActiveSupport::MessageEncryptor.key_len

    old_secret = old_key_generator.generate_key(encrypted_cookie_salt, key_len)
    old_sign_secret = old_key_generator.generate_key(encrypted_signed_cookie_salt, key_len)

    new_secret = new_key_generator.generate_key(encrypted_cookie_salt, key_len)
    new_sign_secret = new_key_generator.generate_key(encrypted_signed_cookie_salt, key_len)

    old_encryptor = ActiveSupport::MessageEncryptor.new(old_secret, old_sign_secret)
    new_encryptor = ActiveSupport::MessageEncryptor.new(new_secret, new_sign_secret)
    new_encryptor.rotate(old_secret, old_sign_secret)

    legacy_token = old_encryptor.encrypt_and_sign('legacy-encrypted-value')

    assert_equal 'legacy-encrypted-value', new_encryptor.decrypt_and_verify(legacy_token)
  end
end
