beercase
===========
ビールケース
重さを計ってGyacoServerに送る

Dependencies
------------

install [serial-socket-gateway](https://github.com/shokai/serial-socket-gateway) and run it.

    % git clone git@github.com:shokai/serial-socket-gateway.git

install rubygems

    % gem install bundler
    % bundle install

see "Gemfile".


Config
======

    % mkdir wavs
    % cp sample.config.yaml config.yaml

put .wav or .mp3 files "wavs" directory.


Calibrate
=========

start serial-socket-gateway, then

    % ruby main.rb calibrate

edit config.yaml


Run
===

    % ruby main.rb

