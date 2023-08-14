require 'cgi'
require 'open-uri'
require 'rss'

class MapperController < ApplicationController
  def index
    render json: { message: "Hello, world!" }
  end

  def map
    url = params[:url]

    if url.nil?
      render json: {
        error: "No URL provided",
      }, status: :bad_request
      return
    end

    url = Addressable::URI.encode(url)
    xml = nil

    OpenURI::open_uri(url) do |f|
      xml = Nokogiri::XML(f)
    end

    if xml.nil?
      render json: {
        error: "Unable to parse XML",
      }, status: :internal_server_error
      return
    end

    xml.css('item').each do |item|
      if item.css('title').text.include? params[:title_exclude]
        item.remove
      end
      offset_hours = params[:offset_hours].to_i
      offset_minutes = params[:offset_minutes].to_i

      if offset_hours != 0 || offset_minutes != 0
        item.css('pubDate').each do |pub_date|
          pub_date.content = (DateTime.parse(pub_date.content) + Rational(offset_hours, 24) + Rational(offset_minutes, 1440)).to_s
        end
      end
    end

    xml.css('channel title').each do |title|
      program_title_postfix = params[:program_title_postfix]
      if program_title_postfix
        title.content = title.content + program_title_postfix
      end
    end

    render xml: xml
  end
end
