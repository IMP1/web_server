#!/usr/bin/env ruby

require_relative 'web_server'
require_relative 'bfj_http_handler'

http_handler = DefaultHttpHandler.new

webserver = WebServer.new(2345, http_handler)
webserver.begin

a = gets.chomp

webserver.stop
