# -*- encoding: utf-8 -*-
# stub: net-ssh-gateway 2.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "net-ssh-gateway".freeze
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jamis Buck".freeze, "Delano Mandelbaum".freeze, "Mikl\u00F3s Fazekas".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDeDCCAmCgAwIBAgIBATANBgkqhkiG9w0BAQUFADBBMQ8wDQYDVQQDDAZuZXRz\nc2gxGTAXBgoJkiaJk/IsZAEZFglzb2x1dGlvdXMxEzARBgoJkiaJk/IsZAEZFgNj\nb20wHhcNMTYxMjE1MTgwNTIyWhcNMTcxMjE1MTgwNTIyWjBBMQ8wDQYDVQQDDAZu\nZXRzc2gxGTAXBgoJkiaJk/IsZAEZFglzb2x1dGlvdXMxEzARBgoJkiaJk/IsZAEZ\nFgNjb20wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDGJ4TbZ9H+qZ08\npQfJhPJTHaDCyQvCsKTFrL5O9z3tllQ7B/zksMMM+qFBpNYu9HCcg4yBATacE/PB\nqVVyUrpr6lbH/XwoN5ljXm+bdCfmnjZvTCL2FTE6o+bcnaF0IsJyC0Q2B1fbWdXN\n6Off1ZWoUk6We2BIM1bn6QJLxBpGyYhvOPXsYoqSuzDf2SJDDsWFZ8kV5ON13Ohm\nJbBzn0oD8HF8FuYOewwsC0C1q4w7E5GtvHcQ5juweS7+RKsyDcVcVrLuNzoGRttS\nKP4yMn+TzaXijyjRg7gECfJr3TGASaA4bQsILFGG5dAWcwO4OMrZedR7SHj/o0Kf\n3gL7P0axAgMBAAGjezB5MAkGA1UdEwQCMAAwCwYDVR0PBAQDAgSwMB0GA1UdDgQW\nBBQF8qLA7Z4zg0SJGtUbv3eoQ8tjIzAfBgNVHREEGDAWgRRuZXRzc2hAc29sdXRp\nb3VzLmNvbTAfBgNVHRIEGDAWgRRuZXRzc2hAc29sdXRpb3VzLmNvbTANBgkqhkiG\n9w0BAQUFAAOCAQEATd8If+Ytmhf5lELy24j76ahGv64m518WTCdV2nIViGXB2BnV\nuLQylGRb1rcgUS3Eh9TE28hqrfhotKS6a96qF9kN0mY2H6UwPWswJ+tj3gA1vLW8\nwlZNlYGJ91Ig9zULPSbATyOOprUZyggy5p1260BaaI3LQYDeGJOSqpHCVu+TuMcy\nk00ofiLT1crDSUl2WE/OIFK8AXpmd798AMsef8okHeoo+Dj7zCXn0VSimN+MO1mE\nL4d54WIy4HkZCqQXoTSiK5HZMIdXkPk3F1bZdJ8Dy1sMRru0rUkkM5mW7TQ75mfW\nZp0QrZyNZhtitrXFbZneGRrIA/8G2Krft5Ly/A==\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2017-01-26"
  s.description = "A simple library to assist in establishing tunneled Net::SSH connections".freeze
  s.email = ["net-ssh@solutious.com".freeze]
  s.homepage = "https://github.com/net-ssh/net-ssh-gateway".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "A simple library to assist in establishing tunneled Net::SSH connections".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.10"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_development_dependency(%q<minitest>.freeze, ["~> 5.8.4"])
      s.add_development_dependency(%q<mocha>.freeze, [">= 1.2.1"])
      s.add_runtime_dependency(%q<net-ssh>.freeze, [">= 4.0.0"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.10"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_dependency(%q<minitest>.freeze, ["~> 5.8.4"])
      s.add_dependency(%q<mocha>.freeze, [">= 1.2.1"])
      s.add_dependency(%q<net-ssh>.freeze, [">= 4.0.0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.10"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.8.4"])
    s.add_dependency(%q<mocha>.freeze, [">= 1.2.1"])
    s.add_dependency(%q<net-ssh>.freeze, [">= 4.0.0"])
  end
end
