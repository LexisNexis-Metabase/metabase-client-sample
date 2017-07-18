# metabase-client-sample
Contains sample code needed to pull articles from LexisNexis Metabase

## What is the Metabase Client Sample?

The purpose of this project is to show you how to work with the Metabase API. Each call to the Metabase API will return a download of the latest articles available in either a JSON feed or an XML feed.

You will need to include the unique profile ID (key) provided to you by Sales or Client Services in each call in order to gain access to the data. To avoid receiving the same articles more than once in consecutive calls to the Metabase there's a special <i>sequence_id</i> parameter that should be used with the scheduled HTTP calls. You need to instruct your program to insert the unique sequence ID number found in the <sequenceId> tag of the last article received in the previous download in your current HTTP request. This instructs the call to start off at the end of the previous request.

This class utilizes the Springboot RestClient class to handle HTTP requests, JAXB annotations to convert the JSON output from the Metabase API to Plain Old Java Objects (POJOs), the IOUtils convenience class to decompressed gzipped output avaliable with the Metabase API, and commons-cli to handle command line arguments. 

If you use Maven for dependency management, the attached pom file contains all the dependencies this sample client uses.

## Parameters

Both the JSON and XML clients take one or many parameters as input.

### key (required)

As stated above, your metabase key will be provided to you by Sales or Client Services. You must supply this as a parameter to the clients or you will not be able to pull articles from Metabase.

### sequenceId (optional)

Each article in Metabase has a sequenceId. As mentioned above, typically you would pass the sequenceId of the last article you received. This tells Metabase to pull the next batch of articles following the previous batch.

### pauseMillis (optional)

This sets the amount of time the client will pause in between calls to Metabase in milliseconds. This is necessary in order to preserve system resources. Most Metabase accounts have restrictions on how often they can call metabase, so there is usually no benefit to setting this value lower. If this value is not set, the client will use the default value of 20000 ms (20 seconds).

### limit (optional)

This limits the number of articles returned by a call to Metabase.

### numSlices (optional)

### sliceIndex (optional)
