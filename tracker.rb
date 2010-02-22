#!/usr/bin/ruby

require 'rubygems'
require 'yaml'
require 'cgi'
require 'activeresource'
require 'RedCloth'

$settings = YAML.load_file("/etc/pivotal-tracker-frontend.yml")

$html_header = <<HEADER
<html><head><title>Project overview</title>
<style type="text/css">
body {
  font-size: 10pt; font-family: lucida grande, arial, sans-serif;
  background: #003300; color: white; }
h1 { font-size: 14pt; }
h2 { font-size: 11pt; }
h2.feature { color: green; }
h2.chore { color: grey; }
h2.bug { color: orange; }
h2.started, h2.finished { color: lightgreen; }
p.description { position: relative; left: 20px; }
</style>
</head>
<body>
HEADER

$html_footer = <<FOOTER
</body>
</html>
FOOTER

class Project < ActiveResource::Base
  attr_reader :short, :hidden_tags, :password
  
  @token = $settings['token']
  self.site = "http://www.pivotaltracker.com/services/v2"
  headers['X-TrackerToken'] = @token

  $settings['projects'].each do |p|
    if p['id'] == self.object_id
      @short = p['short']
      @hidden_tags = []
      for tag in p['hiddentags'].split(",")
        @hidden_tags += tag.split
      end
      @password = p['password']
    end
  end
  
  def stories
    StoryCollection.new(Story.find(:all, :params => { :project_id => self.id }))
  end
  
  def current_stories
    StoryCollection.new(Story.find(:all, :params => { :project_id => self.id }).reject { |item|
      # TODO: Reject stories with hidden tags
      item.current_state == "accepted"
    })
  end
end

class Story < ActiveResource::Base
  @token = $settings['token']
  self.site = "http://www.pivotaltracker.com/services/v2/projects/:project_id"
  headers['X-TrackerToken'] = @token
end

class StoryCollection < Array
  attr_reader :stories

  def initialize(stories = [])
    @stories = stories
  end

  def to_html
    html = ""
    @stories.reject { |s| s.story_type == "chore" }.each do |story| 
      html += "<h2 class=\"#{story.story_type} #{story.current_state}\">" +
        "#{story.story_type.capitalize} #{story.id} - #{story.name}"
      if story.story_type == "release"
        html += " (#{story.deadline.to_s})"
      end
      unless story.current_state == "unstarted"
        html += " (#{story.current_state})\n"
      end
      html += "</h2>\n"
      if story.description
        html += "<p class=\"description\">#{RedCloth.new(story.description).to_html}</p>\n"
      end
    end
    html
  end

  def length
    @stories.length
  end
  
  def to_s
    s = ""
    @stories.each do |story|
      s += "#{story.id}: #{story.name}\n"
    end
    s
  end
end

def web
  cgi = CGI.new

  if not cgi.has_key?('p')
    puts cgi.header('status' => "BAD_REQUEST", 'charset' => "UTF-8")
    puts "<p>No project given. Use ?p=project_name</p>"
  else
    prjid = nil
    $settings['projects'].each do |p|
      if p['short'] == cgi.params['p'][0]
        prjid = p['id']
      end
    end
    if not prjid
      puts cgi.header('status' => "NOT_FOUND", 'charset' => "UTF-8")
      puts "<p>Project #{cgi.params['p'][0]} not found.</p>"
    else  
      puts cgi.header('charset' => "UTF-8")
      puts $html_header
      pt = Project.find(prjid)
      puts "<h1>#{pt.name}</h1>\n"
      puts pt.current_stories.to_html
      puts $html_footer
    end
  end
end

unless ['rake', 'tracker_test.rb'].include?(File.basename($0))
  web
end
