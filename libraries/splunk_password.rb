# coding: UTF-8

# Cookbook Name:: cerner_splunk
# File Name:: splunk_password.rb

require 'base64'

# Module contains different functions to encrypt and decrypt splunk passwords
module CernerSplunk
  # Encrypts the password before writing into config files. As of now all the passwords
  # needs to be XORed except for the sslPassword. The boolean
  # parameter xor controls the XOR logic.
  def self.splunk_encrypt_password(plain_text, splunk_secret, xor = true)
    # Prevent double encrypting values
    return plain_text if plain_text.start_with? '$1$'

    rc4key = splunk_secret.strip[0..15]

    password =
      if xor
        pwd = plain_text.unpack('c*')
        xorkey = get_xor_key(pwd.size)
        pwd.zip(xorkey).map { |c1, c2| c1 ^ c2 }.pack('c*')
      end || plain_text

    '$1$' + Base64.encode64(CernerSplunk::RC4.new(rc4key).encrypt("#{password}\0")).strip!
  end

  # Decrypts the splunk passwords. As of now the encrypted passwords needs to be XORed
  # to retrieve the plain_text for every password except the sslPassword.
  # The boolean parameter xor controls the XOR logic.
  def self.splunk_decrypt_password(encryp_password, splunk_secret, xor = true)
    rc4key = splunk_secret.strip[0..15]
    pwd = CernerSplunk::RC4.new(rc4key).decrypt(Base64.decode64(encryp_password.sub('$1$', ''))).chomp("\0")

    return pwd unless xor

    password = pwd.unpack('c*')
    xorkey = get_xor_key(password.size)
    password.zip(xorkey).map { |c1, c2| c1 ^ c2 }.pack('c*')
  end

  # Return the key used to XOR with the password
  def self.get_xor_key(password_size)
    xorkey = 'DEFAULTSA'.unpack('c*')
    xorkey += xorkey while xorkey.size < password_size
    xorkey
  end
end
