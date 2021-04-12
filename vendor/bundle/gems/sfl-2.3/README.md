# Spawn for Legacy

![demo](http://gyazo.com/e22144b2aadbbecfc43761f95c27bf3e.png)

Kernel.spawn in ruby 1.9 solves all issues on asynchronous executions[[1]](http://ujihisa.blogspot.com/2010/03/how-to-run-external-command.html)[[2]](http://ujihisa.blogspot.com/2010/03/all-about-spawn.html).
But ruby 1.8, the legacy version of MRI, is still used on many environments.

This library provides `spawn()` which is almost perfectly compatible with ruby 1.9's.
This library is pure ruby; you don't need to build it.

## Install

    gem install sfl

## How to use

    require 'rubygems'
    require 'sfl'
    
    spawn 'ls'

If your ruby is 1.9, `require 'sfl'` doesn't do anything. If your ruby is 1.8, that defines `spawn`.

## How compatible this spawn is?

(I'll put the coverage here later)

## Misc.

* At first I tried to use the name `spawn` as this gem library name, but the name was already used. The `spawn` gem library does not mean ruby 1.9's `spawn` at all.
* Ruby 1.9's `open3` library, based on `spawn`, is very useful. I would like to port `open3` to ruby 1.8 in my future.

## Supports

* (On MacOS) MRI 1.8.6, 1.8.7, 1.9.1, 1.9.2-rc2 
* (On UNIX) MRI 1.8.6, 1.8.7, 1.9.1, 1.9.2pre
* (On Windows) MRI 1.9.1, 1.9.2pre

Currently there are no supports on:

* MRI 1.8 on Windows
* Other Ruby implementations such as JRuby, Rubinius and MacRuby

## Authors

Tatsuhiro Ujihisa
<http://ujihisa.blogspot.com/>

Bernard Lambeau
<http://revision-zero.org/>

Kenta Murata
<http://mrkn.jp/>
