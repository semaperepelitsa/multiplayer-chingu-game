#!/usr/bin/env ruby
require 'bundler/setup'
$LOAD_PATH.unshift(File.expand_path('../game', __FILE__))
$LOAD_PATH.unshift(File.expand_path('../game/states', __FILE__))
$LOAD_PATH.unshift(File.expand_path('../game/objects', __FILE__))
$LOAD_PATH.unshift(File.expand_path('../game/traits', __FILE__))
require "window"

Game.new(800, 600, false).show
