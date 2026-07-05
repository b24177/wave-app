# Be sure to restart your server when you modify this file.

# Temporary compatibility layer for the Rails 7 SHA256 key generator migration.
# This accepts cookies encrypted/signed with the previous SHA1-derived keys and
# transparently rewrites them with current keys when read.
# TODO(rails7-cleanup): Remove this initializer after 2026-07-19 once session
# continuity has been verified in production and no legacy-cookie login issues
# are observed.
Rails.application.config.after_initialize do
  next unless Rails.application.config.active_support.key_generator_hash_digest_class == OpenSSL::Digest::SHA256

  secret_key_base = Rails.application.secret_key_base
  key_generator = ActiveSupport::KeyGenerator.new(
    secret_key_base,
    iterations: 1000,
    hash_digest_class: OpenSSL::Digest::SHA1
  )

  encrypted_cookie_salt = Rails.application.config.action_dispatch.encrypted_cookie_salt
  encrypted_signed_cookie_salt = Rails.application.config.action_dispatch.encrypted_signed_cookie_salt
  signed_cookie_salt = Rails.application.config.action_dispatch.signed_cookie_salt

  key_len = ActiveSupport::MessageEncryptor.key_len
  old_encrypted_secret = key_generator.generate_key(encrypted_cookie_salt, key_len)
  old_encrypted_sign_secret = key_generator.generate_key(encrypted_signed_cookie_salt, key_len)
  old_signed_secret = key_generator.generate_key(signed_cookie_salt)

  Rails.application.config.action_dispatch.cookies_rotations.tap do |cookies|
    cookies.rotate :encrypted, old_encrypted_secret, old_encrypted_sign_secret
    cookies.rotate :signed, old_signed_secret
  end
end
