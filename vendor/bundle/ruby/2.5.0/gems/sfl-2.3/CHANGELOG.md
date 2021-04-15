# 2.3

* Make Licence explicit
  * Specify licence in gemspec file
  * Embed LICENCE.md in the gem package
  * Insert full licencing text in LICENCE.md
  * Note that licence itself it unchanged; It's Ruby's, which means
    dual-licence of 2-clause BSDL / the Ruby licence.

# 2.2

* Enhancements

 * Supported shell special characters in a command line string.

* Bugfixes

 * Fix the spec suite for ruby version 1.9.2
 * Stop to overwrite Kernel.spawn and Process.spawn for ruby version 1.9

* Known bugs

 * The spec suite may fail under ruby 1.9.1, due to ruby bugs on some spawn redirect options

# 2.1

* Enhancements

  Added dual licence: Ruby's and 2-clause BSDL along with MRI.

* Bugfixes

  * Resurected Kernel#spawn that was missing in previous release.

# 2.0

Version 2.0 is done completely by Bernard Lambeau. Thanks!

* Enhancements

  * Implemented :in redirection, i.e. spawn("...", :in => ...)
  * Implemented :close redirection, i.e. spawn("...", :out/err/in => :close)
  * Removed spawn override if ruby version is >= 1.9
  * Project structure enhanced with Rakefile and SFL::VERSION
  * Spec suite runs against Kernel.spawn to ensure comptability with native spawn in 1.9

* Bugfixes

  * Fix the spec suite for ruby version 1.9.2

* Known bugs

  * The spec suite may fail under ruby 1.9.1, due to ruby bugs on some spawn redirect options

# 1.2

* Enhancements

  * Added support for quoted command arguments and spaces
  * Defined spawn even if the ruby version is 1.9

# 1.1

* Enhancements

  * Added Process.spawn in addition to Kernel.spawn
  * Added support for Ruby 1.8.6

# 1.0

* Enhancements

  * Birthday


