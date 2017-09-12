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

import ssl

from StringIO import StringIO
from argparse import ArgumentParser
from gzip import GzipFile
from time import sleep
from urllib2 import urlopen, Request, HTTPError
from xml.dom.minidom import parseString

# constants used to help construct the request url to Metabase API

MB_URL_START_STRING = "http://"
MB_HOSTNAME = "metabase.moreover.com"
MB_RESOURCE_NAME = "api/v10/articles"
MB_ACCESS_ID_PARAM_NAME = "key"
MB_SEQUENCE_ID_PARAM_NAME = "sequence_id"
MB_LIMIT_PARAM_NAME = "limit"
MB_NUMBER_OF_SLICES = "number_of_slices"
MB_SLICE_INDEX = "slice_number"

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
# If the volume of your output is such that you need too call more frequently then
# please contact Client Services.
DEFAULT_PAUSE_MILLIS = 20000


# Maximum Download and the <i>limit</i> parameter:
#
# Please note that the maximum number of articles that can be returned in a single Metabase
# call is <b>500</b> articles. Calls that are up to date and set to run at an appropriate interval
# will normally return fewer than 500 articles, i.e. all the current articles that have become
# available since the previous call.
#
# If your calls are continuously hitting the maximum of 500 articles that may indicate you
# are not calling the Metabase frequently enough to keep up with the total output of articles
#
# Example to return only 10 articles:
# http://metabase.moreover.com/api/v10/articles?key=profile_id&sequence_id=id&limit=10
#
# Normally, if you do not provide the limit parameter to the request url

DEFAULT_LIMIT = 500

# constants used for the <status> tag received via Metabase API call

SUCCESS = "SUCCESS"
FAILURE = "FAILURE"

class MetabaseApiTutorial:
    """
        This is a Python implementation on how to use the Metabase API

         The purpose of this class is to show you how to work with the Metabase API.
         Each call to the Metabase API will return a download of the latest articles
         available in an XML feed.
         You will need to include the unique profile ID (key) provided to you by Sales
         or Client Services in each call in order to gain access to the data.
         To avoid receiving the same articles more than once in consecutive calls to the Metabase
         there's a special sequence_id parameter that should be used with the scheduled HTTP calls.
         You need to instruct your program to insert the unique sequence ID number found in the <sequenceId> tag
         of the most recent article received in the previous download in your current HTTP request. This
         instructs the call to start off at the end of the previous request.
    """

    # This will take each arguments from the CommandLine and set the fields so that we can easily work with the
    # values from the command line
    def setFieldsFromArguments(self):

        parser = ArgumentParser()

        parser.add_argument('--key', required=True,
            help='Required: key (key) necessary to build the request URL to MB API')
        parser.add_argument('--hostName', help='provide the hostName for the MB API')
        parser.add_argument('--sequenceId', help='sequence ID in order to call sequentially the MB API')
        parser.add_argument('--pauseMillis', help='pause between 2 calls to the MB API in milliseconds')
        parser.add_argument('--limit', help='maximum of articles to get from MB API (default 500 | maximum 500)')
        parser.add_argument('--numSlices', help='number of slices or clients that will be calling the MB API')
        parser.add_argument('--sliceIndex', help='the slice this client is using for calling the MB API')
        
        results = parser.parse_args()

        self.key = results.key
        self.hostName = results.hostName
        self.sequenceId = results.sequenceId
        self.pauseMillis = None
        if results.pauseMillis is not None:
            self.pauseMillis = int(results.pauseMillis)
        self.limit = None
        if results.limit is not None:
            self.limit = int(results.limit)
            if self.limit < 1 or self.limit > 500:
                self.limit = DEFAULT_LIMIT

        if self.hostName is None:
            self.hostName = MB_HOSTNAME
        if self.pauseMillis is None:
            self.pauseMillis = DEFAULT_PAUSE_MILLIS
            
        self.numSlices = results.numSlices
        self.sliceIndex = results.sliceIndex

    # Constructs a string based on the arguments read from the cmd line
    def constructRequestToMBAPI(self, key, hostName, sequenceId, limit, numSlices, sliceIndex):
        request = MB_URL_START_STRING
        request += str(hostName)
        request += "/"
        request += MB_RESOURCE_NAME
        request += "?"
        request += MB_ACCESS_ID_PARAM_NAME
        request += "="
        request += str(key)
        if sequenceId is not None:
            request += "&"
            request += MB_SEQUENCE_ID_PARAM_NAME
            request += "="
            request += str(sequenceId)
        if limit is not None:
            request += "&"
            request += MB_LIMIT_PARAM_NAME
            request += "="
            request += str(limit)
        if numSlices is not None and sliceIndex is not None:
            request += "&"
            request += MB_NUMBER_OF_SLICES
            request += "="
            request += str(numSlices)
            request += "&"
            request += MB_SLICE_INDEX
            request += "="
            request += str(sliceIndex)

        return request


    # This will be called after the desired arguments are passed.
    # This is a simple http client which will make request url based on the given arguments
    def callMetabaseApi(self):

        # make the call to Metabase API
        requestUrl = self.constructRequestToMBAPI(self.key, self.hostName, self.sequenceId, self.limit, self.numSlices, self.sliceIndex)
        print(requestUrl)
        request = Request(requestUrl)
        request.add_header('Accept-encoding', 'gzip')
        response = urlopen(request, timeout = 30000)
        if response.info().get('Content-Encoding') == 'gzip':
            buf = StringIO( response.read())
            f = GzipFile(fileobj=buf)
            data = f.read()
        else:
            data = response

        nextSeqId = self.handleInputStreamFromResponse(data)

        if nextSeqId is not None:
            return nextSeqId
        else:
            return None

    # Takes the InputStream received from the Metabase API call and parses it to a Document to easily manipulate
    # the data received
    def handleInputStreamFromResponse(self, response):

        # parse the xml from the response
        dom = parseString(response)

        if self.getResponseStatus(dom) == SUCCESS:
            print 'The call to the Metabase API was ', SUCCESS
            print 'Taking the sequenceId from the <sequenceId> tag, used for the next call, in order to avoid duplicates'
            sequenceId = self.getSeqIdFromLastItem(dom)
            print 'setting next sequenceId to: ', sequenceId
            self.printArticles(dom)
            if sequenceId is not None:
                return sequenceId
        else:
            if self.getResponseStatus(dom) == FAILURE:
                print 'The call to the Metabase API was ', FAILURE
                print 'Looking to see what message code and response we received, so we can fix the problems'
                print 'Message code = [ ', self.getMessageCode(dom), ' ]'
                print 'Response = [ ', self.getResponseValue(dom), ' ]'

        return None

    # This will take the value from <status> tag which will be <i>SUCCESS</i> or <i>FAILURE</i>
    def getResponseStatus(self, dom):
        responseElement = dom.getElementsByTagName('response')[0]

        return self.getTagValue('status', responseElement).strip()

    # This will take the last <article> tag from the response of the Metabase API call and take the <sequenceId> value and
    # set it for the following call
    def getSeqIdFromLastItem(self, dom):
        numberOfItems = dom.getElementsByTagName('article').length
        sequenceId = None
        if numberOfItems > 0:
            responseElement = dom.getElementsByTagName('article')[numberOfItems - 1]
            sequenceId = self.getTagValue('sequenceId', responseElement)

            return sequenceId

        return None


    # This will take the value from the <messageCode> tag inside the <response> of the XML
    # which can return the following:
    # - 1000      - Invalid m parameter
    # - 1001      - Profile not found
    # - 1002      - Authentication failure
    # - 1003      - Authorization failure
    # - 1004      - Too frequent calls
    # - 1005      - Unsupported output format associated with the user profile
    # - 1006      - Invalid last_id parameter
    # - 1007      - Invalid limit parameter
    # - 1008      - Invalid sequence_id parameter
    # - 9999      - An error has occurred
    def getMessageCode(self, dom):
        responseElement = dom.getElementsByTagName('response')[0]

        return self.getTagValue('messageCode', responseElement).strip()

    # This will take from the <response>, the <message> tag and return the value of the tag <message>
    def getResponseValue(self, dom):
        responseElement = dom.getElementsByTagName('response')[0]

        return self.getTagValue('message', responseElement).strip()
    
    def getArticleTitle(self, articleElement):
        return self.getTagValue('title', articleElement)
    
    def getArticleUrl(self, articleElement):
        return self.getTagValue('url', articleElement)
    
    # Certain licensed articles require them to be "clicked" to record royalty payments
    # in compliance with LexisNexis rules. This method may be used to call this click url.
    def callMetabaseArticle(self, url):
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        
        try:
            request = Request(url)
            response = urlopen(request, timeout = 30000, context=ctx)
        except HTTPError:
            # This catches and handles any HTTP Errors that may occur when calling a url.
            # Replace "pass" with whatever code you want to use to handle the error
            pass
    
    def getArticleSequenceId(self, articleElement):
        return self.getTagValue('sequenceId', articleElement)
    
    def getArticleLicenses(self, articleElement):
        licenseList = articleElement.getElementsByTagName('license')
        
        if licenseList is not None:
            
            lValues = []
            
            for license in licenseList:
            
                lValues.append(self.getTagValue('name', license))
            
            return lValues
        
        return None

    # helper method to take the node value from the element given as parameter with the associate tag (sTag)
    def getTagValue(self, sTag, element):
        if element.getElementsByTagName(sTag)[0] is not None:
            
            nlList = element.getElementsByTagName(sTag)[0].childNodes

            nValue = nlList[0]

            return nValue.nodeValue.encode("utf-8")

        return None
    
    def printArticles(self, dom):
        numberOfItems = dom.getElementsByTagName('article').length
        for responseElement in dom.getElementsByTagName('article'):
            self.printArticle(responseElement)
            
    def printArticle(self, responseElement):
        print '**********'
        print 'TITLE: ', self.getArticleTitle(responseElement)
        print 'URL: ', self.getArticleUrl(responseElement)
        print 'SEQUENCE ID: ', self.getArticleSequenceId(responseElement)
        print 'LICENSES: '
        for license in self.getArticleLicenses(responseElement):
            print '\t', license

    # pause for how long we set the pauseMillis to be
    def sleepBetweenCalls(self):
        print 'Sleeping for ', self.pauseMillis, ' milliseconds'
        pauseSeconds = self.pauseMillis / 1000
        sleep(pauseSeconds)
        print '------------------------------------------------------------'

# This is where the main functionality is:
# - take the arguments from the command line
# - construct a request url based on these arguments
# - receive the next sequenceId so we can make sequential calls to the Metabase API
# (this is only to avoid receiving duplicate articles)
# - pause the next call (minimum 20 seconds) in order to not get denial of access from the Metabase API
def main():
    tutorial = MetabaseApiTutorial()

    tutorial.setFieldsFromArguments()

    while True:
        # make a call to the Metabase API with the given fields.
        # this will return the next sequenceId in order to know from where to start for the next call
        # (this will avoid getting duplicates)

        nextSeqId = tutorial.callMetabaseApi()

        # set the sequenceId with the next sequenceId received from the InputStream
        tutorial.sequenceId = nextSeqId

        tutorial.sleepBetweenCalls()



## this is to help invoke the main function
if __name__ == '__main__':
    main()
