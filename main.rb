#!/usr/bin/env ruby
# -*- coding: utf-8 -*-
require 'rubygems'
require 'bundler/setup'
require 'socket'
require 'eventmachine'
require 'yaml'
require 'rainbow'
require File.dirname(__FILE__)+'/lib/upload_client'

$KCODE = 'u'
calibrate = true if ARGV.first =~ /^c/i

begin
  conf = YAML::load open(File.dirname(__FILE__)+'/config.yaml')
rescue => e
  STDERR.puts 'config.yaml load error'.color(:red)
  STDERR.puts e.color(:red)
  exit 1
end
p conf
unless calibrate
  zv = conf['weights']['0']
  p gs = conf['weights'].keys.delete_if{|k|k=='0'}.map{|k|
    v = conf['weights'][k]
    (zv - v)/k.to_f
  }
  puts g1 = gs.inject{|a,b|a+b}.to_f/gs.size
end

HOST = "localhost"
PORT = 8782

begin
  s = TCPSocket.open(HOST, PORT)
rescue => e
  STDERR.puts e.color(:red)
  STDERR.puts 'cannot connect serial-socket-gateway'.color(:red)
end

weight = 0 # sensor
median = 0
g = 0 # weight (g)
weight_tmps = Array.new
last_upload = nil

EventMachine::run do
  EventMachine::defer do
    loop do
      res = s.gets
      exit unless res
      res.chop!.strip!
      next if res.to_s.size < 1
      weight_tmps << res.to_i
      if weight_tmps.size >= 100
        weight = (weight_tmps.inject{|a,b|a+b}.to_f/weight_tmps.size)
        median = weight_tmps.map{|i|
          d = i-weight
          d *= -1 if d < 0
          d
        }.inject{|a,b|a+b}/weight_tmps.size
        puts "sensor : #{weight}"
        puts "median : #{median}"
        weight_tmps.clear
      end
    end
  end

  EventMachine::defer do
    loop do
      break if calibrate
      g = (zv-weight)/g1
      puts "weight : #{g} (g)".color(:green)
      if median < 1.5 # センサ値平均がガタついてない時
        conf['objects'].each{|k,v|
          if v-5 < g and g < v+5 # 重さがほぼ同じ
            if last_upload != k # 同じ物をアップロードしない
              puts "detect => #{k.split(/\./).first}".color(0,0,200)
              puts "upload #{k}"
              begin
                UploadClient::upload("wavs/#{k}", conf['api']+'/upload')
              rescue => e
                STDERR.puts e.color(:red)
              end
            end
            last_upload = k
          end
        }
        if -5 < g and g < 5 # 何も無い
          last_upload = nil
          puts 'detect => !empty!'.color(200,0,0)
        end
      end
      sleep 1
    end
  end

  EventMachine::defer do
    loop do
      s.puts gets
    end
  end
end

