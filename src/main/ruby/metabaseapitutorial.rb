#!/usr/bin/ruby -w

#
# This script has been created by Lexis Nexis for demonstration only. Please use discretion, as
# Lexis Nexis cannot be responsible for the results of using this code. Feel free to use as-is or
# to modify it.
#
# www.lexisnexis.com
# January 17, 2013
#
# Updated on:
# September 13, 2016
#

require 'pry'
require 'optparse'
require 'net/http'
require 'uri'
require 'rexml/document'
require 'rexml/xpath'
require 'stringio'
require 'zlib'
include REXML
=begin
 The purpose of this class is to show you how to work with the Metabase API.
 Each call to the Metabase API will return a download of the latest articles
 available in an XML feed.
 You will need to include the unique profile ID (key) provided to you by Sales
 or Client Services in each call in order to gain access to the data.
 To avoid receiving the same articles more than once in consecutive calls to the Metabase
 there's a special <i>sequence_id</i> parameter that should be used with the scheduled HTTP calls.
 You need to instruct your program to insert the unique sequence ID number found in the <sequenceId> tag
 of the most recent article received in the previous download in your current HTTP request. This
 instructs the call to start off at the end of the previous request.
=end
class MetabaseApiTutorial

=begin
  constants used to help construct the request url to Metabase API
=end
  MB_URL_START_STRING = "http://"
  MB_HOSTNAME = "metabase.moreover.com"
  MB_RESOURCE_NAME = "api/v10/articles"
  MB_ACCESS_ID_PARAM_NAME = "key"
  MB_SEQ_ID_PARAM_NAME = "sequence_id"
  MB_LIMIT_PARAM_NAME = "limit"
  MB_COMPACT = "compact"

=begin
  You should schedule calls frequently enough to ensure you keep up with the daily volume of
  articles coming through in your Metabase feed.

  Customers set to receive all English language content would need to schedule calls to run once
  every <b>30</b>seconds (30000 milliseconds) in order to keep up with the volume of articles. Customers set to receive
  fewer articles, for example only posts from specific blogs or categories, may call less frequently,
  e.g. every couple of minutes. Please contact Client Services if you wish to discuss the
  appropriate call frequency for your configuration.

  Please note that there is a standard access limit set at <b>20</b>seconds (20000 milliseconds)
  between calls to the Metabase servers. More frequent calls may result in a denial of access for
  that call.

  If the volume of your output is such that you need too call more frequently then
  please contact Client Services.
=end

  DEFAULT_PAUSE_MILLIS = 20000

=begin
  Maximum Download and the <i>limit</i> parameter:

  Please note that <b>500</b> articles is the maximum that can be returned in a single Metabase
  call. Calls that are up to date and set to run at an appropriate interval
  will normally return fewer than 500 articles, i.e. all the current articles that have become
  available since the previous call.

  If your calls are continuously hitting the maximum of 500 articles that may indicate you
  are not calling the Metabase frequently enough to keep up with the total output of articles

  Example to return only 10 articles:
  http://metabase.moreover.com/api/v10/articles?key=profile_id&sequence_id=id&limit=10

  Normally, if you do not provide the limit parameter to the request url
=end
  DEFAULT_LIMIT = 500

=begin
  constants used for the <status> tag received via Metabase API call
=end

  SUCCESS = "SUCCESS"
  FAILURE = "FAILURE"

  attr_accessor :key, :hostName, :sequenceId, :pauseMillis, :limit, :withContent, :withContentWithMarkup, :withLanguageCode, :compactResponse

  def set_fields_from_arguments

    options = {}

    optparse = OptionParser.new do |opts|
      opts.banner = "Usage: metabaseapitutorial.rb --key key [--hostName] [--sequenceId] [--pauseMillis] [--limit]"

      options[:key] = nil
      opts.on('-m', '--key key', 'Required: key (key) necessary to build the request URL to MB API') do |key|
        options[:key] = key
      end

      options[:hostName] = nil
      opts.on('-b', '--hostName hostName', 'provide the hostName for the MB API') do |hostName|
        options[:hostName] = hostName
      end

      options[:sequenceId] = nil
      opts.on('-s', '--sequenceId sequenceId', 'provide the baseUrl for the MB API') do |sequenceId|
        options[:sequenceId] = sequenceId
      end

      options[:withContent] = nil
      opts.on('-c', '--with-content', 'provide if you want to show article content') do |withContent|
        options[:withContent] = true
      end

      options[:withContentWithMarkup] = nil
      opts.on('-m', '--with-content-with-markup', 'provide if you want to show article contentWithMarkup') do |withContentWithMarkup|
        options[:withContentWithMarkup] = true
      end

      options[:withLanguageCode] = nil
      opts.on('-l', '--with-language-code', 'provide if you want to show article languageCode') do |withLanguageCode|
        options[:withLanguageCode] = true
      end

      options[:compact] = nil
      opts.on('--compact', 'provide if you want to get compact response') do |compact|
        options[:compact] = true
      end

      options[:pauseMillis] = nil
      opts.on('-p', '--pauseMillis pauseMillis', 'provide the baseUrl for the MB API') do |pauseMillis|
        options[:pauseMillis] = pauseMillis
      end

      options[:limit] = nil
      opts.on('-d', '--limit limit', 'provide the baseUrl for the MB API') do |limit|
        options[:limit] = limit
      end
    end

    optparse.parse!

    # raise exception if key is not specified
    raise OptionParser::MissingArgument,'Please specify key argument' if options[:key].nil?

    self.key=options[:key]

    if options[:hostName] != nil
      self.hostName=options[:hostName]
    else
      self.hostName=MB_HOSTNAME
    end

    if options[:sequenceId] != nil
      self.sequenceId=options[:sequenceId]
    else
      self.sequenceId=nil
    end

    if options[:pauseMillis] != nil
      self.pauseMillis=options[:pauseMillis]
    else
      self.pauseMillis=DEFAULT_PAUSE_MILLIS
    end

    if options[:limit] != nil
      self.limit=options[:limit]
    else
      self.limit=nil
    end

    self.withContent = options[:withContent]
    self.withContentWithMarkup = options[:withContentWithMarkup]
    self.withLanguageCode = options[:withLanguageCode]
    self.compactResponse = options[:compact]
  end

=begin
  This will be called after the desired arguments are passed.

  This is a simple http client which will make request url based on the given arguments
=end
  def call_metabase_api
    # make the call to Metabase API
    request_url = construct_request_url_to_mbapi()

    page = nil
    uri = URI.parse(request_url)
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.request_uri)
    print("Accept-Encoding=gzip\n")
    req["Accept-Encoding"] ="gzip"
    print("User-Agent=gzip\n")
    req["User-Agent"] ="gzip"
    print("Performing HTTP GET request for (#{request_url})\n")
    res = http.request(req)
    print("Received HTTP Response Code (#{res.code})\n")
    case res
      when Net::HTTPSuccess then
        begin
          if res['content-encoding'].eql?('gzip')
            sio = StringIO.new(res.body)
            gz = Zlib::GzipReader.new(sio)
            page = gz.read()
          else
            page = res.body
          end
        rescue Exception
          puts("Error occurred (#{$!.message})\n")
          # handle errors
          raise $!.message
        end
    end

    next_sequence_id = self.handle_input_stream_from_response(page)

    next_sequence_id != nil ? next_sequence_id : nil
  end

  # Takes the InputStream received from the Metabase API call, parse it to a Document using REXML, to easily manipulate
  # the data received
  def handle_input_stream_from_response(page)
    doc = REXML::Document.new(page)

    if self.get_response_status(doc) == SUCCESS
      print "The call to Metabase API was ", SUCCESS, "\n"
      print "Taking the sequenceId from the <sequenceId> tag, used for the next call, in order to avoid duplicates \n"
      sequence_id = self.get_sequence_id_from_last_article(doc)
      print "Setting next sequenceId to: ", sequence_id, "\n"
      self.print_articles(doc)
      if sequence_id != nil
        return sequence_id
      end
    else
      if self.get_response_status(doc) == FAILURE
        print "The call to Metabase API was ", FAILURE, "\n"
        print "Looking to see what message code and response we received, so we can fix the problems\n"
        print "Message code = [ ", get_message_code(doc), " ]\n"
        print "Response = [ ", get_response_value(doc), " ]\n"
      end
    end

    nil
  end

  # This prints the articles from the InputStream received from the Metabase API call
  def print_articles(articlesDoc)
    articlesDoc.root.elements.to_a("/response/articles/article").each do |article|
      self.print_article(article)
    end
    nil
  end

  # This prints a single article, with the data coming from the passed document
  def print_article(articleElement)
    print "**********\n"
    print_article_text_prop("title", articleElement)
    print_article_text_prop("content", articleElement) if self.withContent
    print_article_text_prop("contentWithMarkup", articleElement) if self.withContentWithMarkup
    print_article_text_prop("url", articleElement)
    print_article_text_prop("sequenceId", articleElement)
    print_article_text_prop("languageCode", articleElement) if self.withLanguageCode
    print_article_array_prop("licenses", "licenses/license/name", articleElement)
    nil
  end

  def print_article_text_prop(propertyName, articleElement)
    propertyValue = articleElement.elements[propertyName]
    print "#{snakecase(propertyName).upcase}: "
    if propertyValue.nil? || propertyValue.text.nil?
      print "(null)", "\n"
    else
      print articleElement.elements[propertyName].text.strip, "\n"
    end
  end

  def print_article_array_prop(label, propertyName, articleElement)
    print "#{snakecase(label).upcase}:\n"
    if articleElement.elements[propertyName]
      articleElement.elements[propertyName].each do |elem|
        print "\t", elem, "\n"
      end
    else
      print "\t(no #{label} available)\n"
    end
  end


  # Certain licensed articles require them to be "clicked" to record royalty payments
  # in compliance with LexisNexis rules. This method may be used to call this click url.
  def call_metabase_article(url)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Get.new(uri.request_uri)
    print("Performing HTTP GET request for (#{url})\n")
    res = http.request(req)
    print("Received HTTP Response Code (#{res.code})\n")
  end

  # This will take from the <response>, the <message> tag and return the value of the tag <message>
  def get_response_value(doc)
    doc.root.elements["//response/message"].text.strip
  end

=begin
  This will take from the <response>, the <messageCode> tag which can return the following:
   - 1000      - Invalid key parameter
   - 1001      - Profile not found
   - 1002      - Authentication failure
   - 1003      - Authorization failure
   - 1004      - Too frequent calls
   - 1005      - Unsupported output format associated with the user profile
   - 1006      - Invalid last_id parameter
   - 1007      - Invalid limit parameter
   - 1008      - Invalid sequence_id parameter
   - 9999      - An error has occurred
=end
  def get_message_code(doc)
    doc.root.elements["//response/messageCode"].text.strip
  end

  # This will take the last <article> tag from the response of the Metabase API call and take the <sequenceId> value and
  # set it for the following call
  def get_sequence_id_from_last_article(doc)
    number_of_articles = doc.root.elements.to_a("//article").length
    if number_of_articles > 0
      doc.root.elements.to_a("//article")[number_of_articles - 1].elements["sequenceId"].text
    end
  end

  # This will take from the <response> tag, the <status> tag which will be SUCCESS or FAILURE
  def get_response_status(doc)
    doc.root.elements["//response/status"].text.strip
  end

# Constructs a string based on the arguments read from the cmd line
  def construct_request_url_to_mbapi
    request = MB_URL_START_STRING
    request += self.hostName
    request += "/"
    request += MB_RESOURCE_NAME
    request += "?"
    request += MB_ACCESS_ID_PARAM_NAME
    request += "="
    request += self.key
    if self.sequenceId != nil
      request += "&"
      request += MB_SEQ_ID_PARAM_NAME
      request += "="
      request += self.sequenceId
    end
    if self.limit != nil
      request += "&"
      request += MB_LIMIT_PARAM_NAME
      request += "="
      if self.limit.to_i < 1 or self.limit.to_i > 500
        request += DEFAULT_LIMIT
      else
        request += self.limit
      end
    end

    if self.compactResponse
      request += "&#{MB_COMPACT}=true"
    end

    request
  end

  # pause for how long we set the pauseMillis to be
  def sleep_between_calls
    print 'Sleeping for ', self.pauseMillis, ' milliseconds', "\n"
    pause_seconds = (self.pauseMillis.to_i / 1000)
    sleep(pause_seconds)
    puts '------------------------------------------------------------'
  end

  # make camelCase to snake_case
  def snakecase(s)
    s.gsub(/::/, '/').
      gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
      gsub(/([a-z\d])([A-Z])/,'\1_\2').
      tr("-", "_").
      downcase
  end

end


=begin
  This is where the main functionality is:
  - take the arguments from the command line
  - construct a request url based on these arguments
  - make call to the Metabase API
  - receive the next sequenceId so we can make sequential calls to the Metabase API
  (this is only to avoid receiving duplicate articles)
  - pause the next call (minimum 20 seconds) in order to not get denial of access from the Metabase API
=end
def main

  tutorial = MetabaseApiTutorial.new

  tutorial.set_fields_from_arguments()

  while true
    # make a call to the Metabase API with the given fields.
    # this will return the next sequenceId in order to know from where to start for the next call
    # (this will avoid getting duplicates)

    next_sequence_id = tutorial.call_metabase_api()

    STDOUT.flush

    # set the sequenceId with the next sequenceId received from the InputStream
    tutorial.sequenceId=next_sequence_id

    tutorial.sleep_between_calls()

  end
end

## this is to help invoke the main function
if __FILE__ == $0
  main()
end