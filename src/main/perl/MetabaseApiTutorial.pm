#!/usr/bin/perl

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

use strict;
use warnings;
use LWP::UserAgent;
use HTTP::Message;
use XML::DOM;

# The purpose of this class is to show you how to work with Metabase API
# Each call to the Metabase API will return a download of the latest articles
# available in an XML feed.
# You will need to include the unique profile ID (key) provided to you by Sales
# or Client Services in each call in order to gain access to the data.
# To avoid receiving the same articles more than once in consecutive calls to the Metabase
# there is a <i>sequence_id</i> parameter that should be used with the scheduled HTTP calls.
# You need to instruct your program to insert the unique sequence ID number found in the <sequenceId> tag
# of the most recent article received in the previous download in your current HTTP request. This
# instructs the call to start off at the end of the previous request.

package MetabaseApiTutorial;

# constants used to help construct the request url to Metabase API

use constant {
    MB_URL_START_STRING => "http://",
    DEFAULT_MB_HOSTNAME => "metabase.moreover.com",
    MB_RESOURCE_NAME => "api/v10/articles",
    MB_ACCESS_ID_PARAM_NAME => "key",
    MB_SEQUENCE_ID_PARAM_NAME => "sequence_id",
    MB_LIMIT_PARAM_NAME => "limit",
    MB_CALL_TIMEOUT_MS => 30000
};


 # You should schedule calls frequently enough to ensure you keep up with the daily volume of
 # articles coming through in your Metabase feed.
 #    
 # Customers set to receive all English language content would need to schedule calls to run once
 # every <b>30</b>seconds (30000 milliseconds) in order to keep up with the volume of articles. Customers set to receive
 # fewer articles, for example only posts from specific blogs or categories, may call less frequently,
 # e.g. every couple of minutes. Please contact Client Services if you wish to discuss the
 # appropriate call frequency for your configuration.
 #    
 # Please note that there is a standard access limit set at <b>20</b>seconds (20000 milliseconds)
 # between calls to the Metabase servers. More frequent calls may result in a denial of access for
 # that call.
 #    
 # If the volume of your output is such that you need to call more frequently then
 # please contact Client Services.
     
use constant DEFAULT_PAUSE_MILLIS => 20000;  

# Maximum Download and the <i>limit</i> parameter:
#
# Please note that the maximum number of articles that can be returned in a single Metabase
# call is <b>500</b>. Calls that are up to date and set to run at an appropriate interval
# will normally return fewer than 500 articles, i.e. all the current articles that have become
# available since the previous call.
#
# If your calls are continuously hitting the maximum of 500 articles that may indicate you
# are not calling the Metabase frequently enough to keep up with the total output of articles.
#
# Example to return only 10 articles:
# <i>http://metabase.moreover.com/api/v10/articles?key=profile_id&sequence_id=id&limit=10</i>
#
# If you do not provide the limit parameter to the request url it defaults to 500.

use constant DEFAULT_LIMIT => 500;

# constants used for the <status> tag received via Metabase API call

use constant SUCCESS => "SUCCESS";
use constant FAILURE => "FAILURE";


sub new {
        
    # constructor
    my $self = {};

    # these are the fields which will be set in respect to what we give as arguments to the MetabaseApiTutorial class
    $self->{key}    = undef;
    $self->{hostName}    = undef;
    $self->{sequenceId}  = undef;
    $self->{pauseMillis} = undef;
    $self->{limit}       = undef;
    bless($self);

    return $self;
}

# methods to access per-object data
# w/ args, they behave like setters.
# w/o args, they behave like getters.

sub key {
    my $self = shift;
    if (@_) { $self->{key} = shift }
    return $self->{key};
}

sub hostName {
    my $self = shift;
    if (@_) { $self->{hostName} = shift }
    return $self->{hostName};
}

sub sequenceId {
    my $self = shift;
    if (@_) { $self->{sequenceId} = shift }
    return $self->{sequenceId};
}

sub pauseMillis {
    my $self = shift;
    if (@_) { $self->{pauseMillis} = shift }
    return $self->{pauseMillis};
}

sub limit {
    my $self = shift;
    if (@_) { $self->{limit} = shift }
    return $self->{limit};
}

# end methods to access per-object data


# Constructs a string based on the arguments read from the cmd line

sub constructRequestUrlToMBAPI {    
    my $key = shift;
    my $hostName = shift;
    my $sequenceId = shift;
    my $limit = shift;
    
    my $requestUrl = MetabaseApiTutorial->MB_URL_START_STRING . $hostName . "/";
    $requestUrl = $requestUrl . MetabaseApiTutorial->MB_RESOURCE_NAME . "?";
    $requestUrl = $requestUrl . MetabaseApiTutorial->MB_ACCESS_ID_PARAM_NAME . "=" . $key;


    if($sequenceId) {
        $requestUrl = $requestUrl . "&";
        $requestUrl = $requestUrl . MetabaseApiTutorial->MB_SEQUENCE_ID_PARAM_NAME . "=" . $sequenceId;
    }
    
    if($limit) {
        if ($limit < 1 || $limit > 500) {
            $requestUrl = $requestUrl . "&";
            $requestUrl = $requestUrl . MetabaseApiTutorial->MB_LIMIT_PARAM_NAME . "=" .
            MetabaseApiTutorial->DEFAULT_LIMIT;
        } else {
            $requestUrl = $requestUrl . "&";
            $requestUrl = $requestUrl . MetabaseApiTutorial->MB_LIMIT_PARAM_NAME . "=" . $limit;
        }
    }

    return $requestUrl;
};

# helper method to take the node value from the element given as parameter with the associate tag (sTag)
sub getTagValue {
    my $sTag = shift;
    my $element = shift;
    
    if($element->getElementsByTagName($sTag)->item(0)) {
        my $nlList = $element->getElementsByTagName($sTag)->item(0)->getChildNodes();
        
        return $nlList->item(0)->getNodeValue();
    }
    
    return undef;
}

# This will take the last <article> tag from the response of the Metabase API call and take the <sequenceId> value and
# set it for the following call
sub getSequenceIdFromLastItem {
    my $doc = shift;
    
    my $numberOfItems = $doc->getElementsByTagName("article")->getLength();
    
    my $responseElement;
    my $sequenceId;
    
    if($numberOfItems > 0) {
        $responseElement = $doc->getElementsByTagName("article")->item($numberOfItems - 1);
        $sequenceId = &getTagValue("sequenceId", $responseElement);
        
        return $sequenceId;
    }
    
    return undef;
}

# This will take the value from the <status> tag which will be <i>SUCCESS</i> or <i>FAILURE</i>
sub getResponseStatus {
    my $doc = shift;
    
    my $responseElement = $doc->getElementsByTagName("response")->item(0);
    
    return &getTagValue("status", $responseElement);
    
}

# This will take from the <messageCode> tag inside the <response> of the XML
# which can return the following:
#      - 1000      - Invalid key parameter
#      - 1001      - Profile not found
#      - 1002      - Authentication failure
#      - 1003      - Authorization failure
#      - 1004      - Too frequent calls
#      - 1005      - Unsupported output format associated with the user profile
#      - 1006      - Invalid last_id parameter
#      - 1007      - Invalid limit parameter
#      - 1008      - Invalid sequence_id parameter
#      - 9999      - An error has occurred
sub getMessageCode {
    my $doc = shift;

    my $responseElement = $doc->getElementsByTagName("response")->item(0);

    return &getTagValue("messageCode", $responseElement);
}

sub printArticles {
    my $doc = shift;
    
    foreach my $article ($doc->getElementsByTagName("article")) {
        &printArticle($article);
    }
    
    return;
}

sub printArticle {
    my $article = shift;
    
    print "**********" . "\n";
    print "TITLE: " . &getTagValue("title",$article) . "\n";
    print "URL: " . &getTagValue("url",$article) . "\n";
    print "SEQUENCE ID: " . &getTagValue("sequenceId",$article) . "\n";
    print "LICENSES:" . "\n";
    
    foreach my $license ($article->getElementsByTagName("license")) {
        print "\t" . &getTagValue("name", $license) . "\n";
    }
    
    &callArticleUrl(&getTagValue("url",$article));
    
    return;
}

# Certain licensed articles require them to be "clicked" to record royalty payments
# in compliance with LexisNexis rules. This method may be used to call this click url.
sub callArticleUrl {
    my $articleUrl = shift;
    
    my $ua = LWP::UserAgent->new();
    
    $ua->ssl_opts(verify_hostname => 0);
    
    my $response = $ua->get($articleUrl);
    
    return;
}

# This will take from the <response>, the <message> tag and return the value of the tag <message>
sub getResponseValue {
    my $doc = shift;
    
    my $responseElement = $doc->getElementsByTagName("response")->item(0);
    
    return &getTagValue("message", $responseElement);
}

# Takes the InputStream received from the Metabase API call and parses it to a Document to easily manipulate
# the data received
sub handleInputStreamFromResponse {
    my $content = shift;
    
    my $parser = new XML::DOM::Parser;

    # for wget: 
    # we will do my $doc = $parser->parsefile($content), because of file.xml is a file
    my $doc = eval { $parser->parse($content) };
    if ($@) {
        die("Error: could not parse XML from response: $@\nContent: \n\n[[$content]]\n\n");
    }

    my $responseStatus = &getResponseStatus($doc);
    
    if($responseStatus eq MetabaseApiTutorial->SUCCESS) {
        print "The call to Metabase API was " . MetabaseApiTutorial->SUCCESS . "\n";
        print "Taking the sequenceId from the <sequenceId> tag, used for the next call, in order to avoid duplicates\n";
        
        my $sequenceId = &getSequenceIdFromLastItem($doc);
        
        if ($sequenceId) {
            print "setting next sequenceId to " . $sequenceId . "\n";
            &printArticles($doc);
            return $sequenceId;
        }
    } else {
        if($responseStatus eq MetabaseApiTutorial->FAILURE) {
            print "The call to Metabase API was " . MetabaseApiTutorial->FAILURE . "\n";
            print "Looking to see what message code and response we received, so we can fix the problems\n";
            print "Message code = [ " . &getMessageCode($doc) . " ]\n";
            print "Response = [ " . &getResponseValue($doc) . " ]\n";
        }
    }

    return undef;   
}


# This will be called after the desired arguments are passed.
#
# This is a simple http client which will make request url based on the given arguments
#
# There are 3 possibilities to make requests to the metabase API:
#   1) LWP (used in this tutorial)
#   2) CURL (commented out)
#   3) WGET (commented out)
sub callMetabaseApi {
    my $self = shift;
    
    my $key = shift;
    my $hostName = shift;
    my $sequenceId = shift;
    my $limit = shift;

    ## use this if you want CURL    
    #    my $curl = WWW::Curl::Easy->new();
    #    
    #    $curl->setopt(WWW::Curl::Easy->CURLOPT_HEADER,1);
    #    $curl->setopt(WWW::Curl::Easy->CURLOPT_URL, &constructRequestUrlToMBAPI($key, $hostName, $sequenceId, $limit));
    #    $curl->setopt(WWW::Curl::Easy::CURLOPT_HTTPHEADER(), ['Content-Type: application/xml; charset=UTF-8', 'Content-Encoding: gzip']);
    #    
    #    my $response_body;
    #    $curl->setopt(WWW::Curl::Easy->CURLOPT_WRITEDATA, \$response_body);
    #    start the actual request
    #    my $return_code = $curl->perform();
    ## end CURL
    my $requestUrl = &constructRequestUrlToMBAPI($key, $hostName, $sequenceId, $limit);
    # Create a request
    my $ua = LWP::UserAgent->new();
    my $can_accept = HTTP::Message::decodable;
    $ua->timeout(MB_CALL_TIMEOUT_MS);
    $ua->default_header('Accept-Encoding' => $can_accept);
    my $response = $ua->get($requestUrl,
        'Accept-Encoding' => $can_accept,
    );
    
    # we can do the request via wget command, which will save the response content into file.xml
    # follow the instructions in handleInputStreamFromResponse on how to parse the file.xml
    # system("wget -o file.xml $requestUrl");
    
    my $nextSequenceId = &handleInputStreamFromResponse($response->decoded_content(charset => 'none'));
    
    return ($nextSequenceId) ? $nextSequenceId : undef;
};

1;
