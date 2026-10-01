#!/usr/bin/env ruby
# frozen_string_literal: true

# Renders a shields-style SVG badge from SimpleCov's .last_run.json.
#   script/coverage_badge.rb coverage/.last_run.json coverage.svg

require 'json'

input, output = ARGV
abort "usage: #{$PROGRAM_NAME} <.last_run.json> <out.svg>" unless input && output

result = JSON.parse(File.read(input)).fetch('result')
percent = (result['line'] || result.fetch('covered_percent')).to_f
label = "#{percent.floor(1)}%"

color =
  if percent >= 95 then '#4c1'
  elsif percent >= 90 then '#97ca00'
  elsif percent >= 80 then '#dfb317'
  elsif percent >= 70 then '#fe7d37'
  else '#e05d44'
  end

# ~7px per character at 11px Verdana, plus padding
left_width = 63
right_width = (label.length * 7) + 10
width = left_width + right_width

File.write(output, <<~SVG)
  <svg xmlns="http://www.w3.org/2000/svg" width="#{width}" height="20" role="img" aria-label="coverage: #{label}">
    <title>coverage: #{label}</title>
    <linearGradient id="s" x2="0" y2="100%">
      <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
      <stop offset="1" stop-opacity=".1"/>
    </linearGradient>
    <clipPath id="r"><rect width="#{width}" height="20" rx="3" fill="#fff"/></clipPath>
    <g clip-path="url(#r)">
      <rect width="#{left_width}" height="20" fill="#555"/>
      <rect x="#{left_width}" width="#{right_width}" height="20" fill="#{color}"/>
      <rect width="#{width}" height="20" fill="url(#s)"/>
    </g>
    <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" font-size="11">
      <text x="#{left_width / 2}" y="14">coverage</text>
      <text x="#{left_width + (right_width / 2)}" y="14">#{label}</text>
    </g>
  </svg>
SVG
