# metabase-client-sample
Contains sample code needed to pull articles from LexisNexis Metabase

## What is the Metabase Client Sample

The purpose of this project is to show you how to work with the Metabase API. Each call to the Metabase API will return a download of the latest articles available in either a JSON feed or an XML feed.

You will need to include the unique profile ID (key) provided to you by Sales or Client Services in each call in order to gain access to the data. To avoid receiving the same articles more than once in consecutive calls to the Metabase there's a special <i>sequence_id</i> parameter that should be used with the scheduled HTTP calls. You need to instruct your program to insert the unique sequence ID number found in the <sequenceId> tag of the last article received in the previous download in your current HTTP request. This instructs the call to start off at the end of the previous request.

This class utilizes the Springboot RestClient class to handle HTTP requests, JAXB annotations to convert the JSON output from the Metabase API to Plain Old Java Objects (POJOs), the IOUtils convenience class to decompressed gzipped output avaliable with the Metabase API, and commons-cli to handle command line arguments. 

If you use Maven for dependency management, the attached pom file contains all the dependencies this sample client uses.
