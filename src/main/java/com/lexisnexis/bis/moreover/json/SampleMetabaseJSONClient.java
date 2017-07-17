package com.lexisnexis.bis.moreover.json;

import java.io.ByteArrayInputStream;
import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.List;
import java.util.zip.GZIPInputStream;

import javax.xml.bind.JAXBException;

import org.apache.commons.cli.CommandLine;
import org.apache.commons.cli.CommandLineParser;
import org.apache.commons.cli.DefaultParser;
import org.apache.commons.cli.Option;
import org.apache.commons.cli.Options;
import org.apache.commons.cli.ParseException;
import org.codehaus.jackson.map.ObjectMapper;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.util.StringUtils;
import org.springframework.web.client.RestTemplate;

import com.lexisnexis.bis.moreover.json.metabase.entities.Article;
import com.lexisnexis.bis.moreover.json.metabase.entities.JSONResponse;
import com.lexisnexis.bis.moreover.json.metabase.entities.License;

/**
 * The purpose of this class is to show you how to work with the Metabase API
 * Each call to the Metabase API will return a download of the latest articles
 * available in a JSON feed.
 * 
 * You will need to include the unique profile ID (key) provided to you by Sales
 * or Client Services in each call in order to gain access to the data.
 * To avoid receiving the same articles more than once in consecutive calls to the Metabase
 * there's a special <i>sequence_id</i> parameter that should be used with the scheduled HTTP calls.
 * You need to instruct your program to insert the unique sequence ID number found in the <sequenceId> tag
 * of the last article received in the previous download in your current HTTP request. This
 * instructs the call to start off at the end of the previous request.
 * 
 * This class utilizes the Springboot RestClient class to handle HTTP requests, JAXB annotations
 * to convert the JSON output from the Metabase API to Plain Old Java Objects (POJOs),
 * the IOUtils convenience class to decompressed gzipped output avaliable with the Metabase API,
 * and commons-cli to handle command line arguments. 
 * 
 * If you use Maven for dependency management, the attached pom file contains all the dependencies
 * this sample client uses.
 *
 */
public class SampleMetabaseJSONClient {
    
    /**
     * constants used to help construct the request url to Metabase API
     */
    private static final String MB_ENDPOINT = "http://metabase.moreover.com/api/v10/articles?";
    private static final String MB_KEY_PARAM_NAME = "key";
    private static final String MB_SEQ_ID_PARAM_NAME = "sequence_id";
    private static final String MB_LIMIT_PARAM_NAME = "limit";
    private static final String MB_NUMBER_OF_SLICES = "number_of_slices";
    private static final String MB_SLICE_INDEX = "slice_number";
    private static final String MB_FORMAT = "format";

    /**
     * constants used for the menu
     */
    private static final String KEY_OPTION = "key";
    private static final String SEQ_ID_OPTION = "sequenceId";
    private static final String PAUSE_MILLIS_OPTION = "pauseMillis";
    private static final String LIMIT_OPTION = "limit";
    private static final String NUM_SLICES_OPTION = "numSlices";
    private static final String SLICE_INDEX_OPTION = "sliceIndex";
    
    /**
     * Maximum Download and the <i>limit</i> parameter:
     * <p/>
     * Please note that the maximum number of articles that can be returned in a single Metabase
     * call is <b>500</b> articles. Calls that are up to date and set to run at an appropriate interval
     * will normally return fewer than 500 articles, i.e. all the current articles that have become
     * available since the previous call.
     * <p/>
     * If your calls are continuously hitting the maximum of 500 articles that may indicate you
     * are not calling the Metabase frequently enough to keep up with the total output of articles
     * <p/>
     * Example to return only 10 articles:
     * <i>http://metabase.moreover.com/api/v10/articles?key=profile_id&sequence_id=sequenceId&limit=10</i>
     * <p/>
     * Normally, if you do not provide the limit parameter to the request url it defaults to 500
     */
    private static final Integer DEFAULT_LIMIT = 500;
    
    /**
     * You should schedule calls frequently enough to ensure you keep up with the daily volume of
     * articles coming through in your Metabase feed.
     * <p/>
     * Customers set to receive all English language content would need to schedule calls to run once
     * every <b>30</b>seconds (30000 milliseconds) in order to keep up with the volume of articles. Customers set to receive
     * fewer articles, for example only posts from specific blogs or categories, may call less frequently,
     * e.g. every couple of minutes. Please contact Client Services if you wish to discuss the
     * appropriate call frequency for your configuration.
     * <p/>
     * Please note that there is a standard access limit set at <b>20</b>seconds (20000 milliseconds)
     * between calls to the Metabase servers. More frequent calls may result in a denial of access for
     * that call.
     * <p/>
     * If the volume of your output is such that you need to call more frequently then
     * please contact Client Services.
     */
    private static final int DEFAULT_PAUSE_MILLIS = 20000;

    /**
     * constants used for the status attribute from <response> tag received via Metabase API call
     */
    private static final String SUCCESS = "SUCCESS";
    private static final String FAILURE = "FAILURE";
    
    /**
     * these are the fields which will be set in respect to what we give as arguments to the MetabaseAPITutorial class
     */
    private String key;
    private Long seqId;
    private Integer pauseMillis;
    private Integer limit;
    private Integer numberOfSlices;
    private Integer sliceIndex;
    private String format;
    
    private static ObjectMapper mapper;

    public static void main(String[] args) {
        mapper = new ObjectMapper();

        SampleMetabaseJSONClient client = new SampleMetabaseJSONClient();
        
        client.setFieldsFromArguments(args);
        
        client.run();

    }
    

    
    public void run() {
        
        Long sequenceId = seqId;
        
        RestTemplate restTemplate = new RestTemplate();
        
        /**
         * Add the Accept-Encoding : gzip header
         */
        HttpHeaders headers = new HttpHeaders();
        headers.set("Accept-Encoding", "gzip");
        HttpEntity<String> entity = new HttpEntity<String>("parameters", headers);
        
        try {
            
            while(true) {
                
                long startTime = System.currentTimeMillis();
                
                String metabaseUrl = constructRequestUrlToMBAPI(key, sequenceId, limit, numberOfSlices, sliceIndex, "json");
                
                /**
                 * This uses JAXB to unmarshal the compressed response into a Response object, which
                 * we will use to extract the necessary information and the article(s).
                 */
                byte[] gzipResponse = restTemplate.exchange(metabaseUrl, HttpMethod.GET, entity, byte[].class).getBody();
                JSONResponse response = decompressResponse(gzipResponse);

                /**
                 * This example takes this Response object and prints out each article's
                 * title, click url, and the names of all licenses the article contains.
                 */
                if (response.getStatus().equals(SUCCESS) && response.getArticles() != null) {
                    for (Article article : response.getArticles()) {
                        System.out.println("TITLE: " + article.getTitle());
                        System.out.println("URL: " + article.getUrl());
                        List<String> licenses = new ArrayList<>();
                        if (article.getLicenses() != null) {
                            for (License license : article.getLicenses()) {
                                licenses.add(license.getName());
                            }
                        }
                        System.out.println("LICENSES: [" + StringUtils.collectionToCommaDelimitedString(licenses) + "]");
                        System.out.println("SEQUENCE ID: " + article.getSequenceId() + "\n");
                        
                        /**
                         * Set the local sequenceId variable to the article's sequenceId.
                         */
                        sequenceId = article.getSequenceId();
                        
                        
                    }
                    System.out.println(response.getArticles().size() + " article(s) pulled.");
                } else {
                    System.out.println("Call to Metabase failed with status=[" + response.getStatus() + "]");
                    System.out.println("Message code = [ " + response.getMessageCode() + " ]");
                }
                
                long endTime = System.currentTimeMillis();
                
                if (endTime < (startTime+pauseMillis)) {
                    long diff = startTime + pauseMillis - endTime; 
                    Thread.sleep(diff);
                }
                
            }
        } catch (JAXBException | InterruptedException | IOException e) {
            e.printStackTrace();
        }
    }
    
    /**
     * Basic method that calls any URL passed to it.
     * Certain licensed articles require them to be "clicked" to record royalty payments
     * in compliance with LexisNexis rules. This method may be used to call this click url.
     * 
     * @param url String representation of the URL to call
     */
    private void callUrl(String url) {
        try {
            URL obj = new URL(url);
            HttpURLConnection con = (HttpURLConnection) obj.openConnection();
            
            con.setRequestMethod("GET");
            
            // this is the method that actually does the calling
            int responseCode = con.getResponseCode();
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
    
    /**
     * Constructs a string based on the arguments read from the cmd line
     *
     * @param key   string representing the key
     * @param seqId   long representing the sequenceId
     * @param limit integer representing the maximum number of articles to be returned in the API call
     * @param numSlices integer representing the number of slices or clients calling the API
     * @param sliceIndex integer representing the slice this client is using to call the MB API
     * @param format string representing the format of the output from the MB API
     * @return string representing the request url constructed based on the given arguments
     */
    private String constructRequestUrlToMBAPI(String key, Long seqId, Integer limit, Integer numSlices, Integer sliceIndex, String format) {

        StringBuilder stringBuilder = new StringBuilder();
        stringBuilder.append(MB_ENDPOINT);
        stringBuilder.append(MB_KEY_PARAM_NAME).append("=").append(key);
        if (seqId != null) {
            stringBuilder.append("&");
            stringBuilder.append(MB_SEQ_ID_PARAM_NAME).append("=").append(seqId);
        }
        if (limit != null) {
            if (limit < 1 || limit > 500) {
                stringBuilder.append("&");
                stringBuilder.append(MB_LIMIT_PARAM_NAME).append("=").append(DEFAULT_LIMIT);
            } else {
                stringBuilder.append("&");
                stringBuilder.append(MB_LIMIT_PARAM_NAME).append("=").append(limit);
            }
        }
        if (numSlices != null && sliceIndex != null) {
                stringBuilder.append("&");
            stringBuilder.append(MB_NUMBER_OF_SLICES).append("=").append(numSlices);
                stringBuilder.append("&");
            stringBuilder.append(MB_SLICE_INDEX).append("=").append(sliceIndex);
        }
        if (!StringUtils.isEmpty(format) && format.equalsIgnoreCase("json")) {
            stringBuilder.append("&");
            stringBuilder.append(MB_FORMAT).append("=").append("json");
        }
        System.out.println(stringBuilder.toString());

        return stringBuilder.toString();
    }
    
    /**
     * Convenience method to convert a gzipped byte array to a Response object.
     * 
     * @param compressedData The byte array containing gzipped data
     * @return The decompressed response as a Response object
     * @throws UnsupportedEncodingException
     * @throws IOException
     * @throws JAXBException
     */
    private JSONResponse decompressResponse(byte[] compressedData) throws UnsupportedEncodingException, IOException, JAXBException {
        GZIPInputStream gis = new GZIPInputStream(new ByteArrayInputStream(compressedData));
        return mapper.readValue(gis, JSONResponse.class);
    }

    /**
     * This will take each argument from the CommandLine and set the fields so that we can easily work with the
     * values from the command line
     *
     * @param args arguments from the command line
     */
    private void setFieldsFromArguments(String[] args) {
        CommandLine commandLine = parseArgumentsGivenAsParameters(args);

        key = commandLine.getOptionValue(KEY_OPTION);
        seqId = commandLine.getOptionValue(SEQ_ID_OPTION) != null ?
                Long.parseLong(commandLine.getOptionValue(SEQ_ID_OPTION)) :
                null;
        pauseMillis = commandLine.getOptionValue(PAUSE_MILLIS_OPTION) != null ?
                Integer.parseInt(commandLine.getOptionValue(PAUSE_MILLIS_OPTION)) :
                DEFAULT_PAUSE_MILLIS;
        limit = commandLine.getOptionValue(LIMIT_OPTION) != null ?
                Integer.parseInt(commandLine.getOptionValue(LIMIT_OPTION)) :
                null;
        numberOfSlices = commandLine.getOptionValue(NUM_SLICES_OPTION) != null ?
                Integer.parseInt(commandLine.getOptionValue(NUM_SLICES_OPTION)) :
                null;
        sliceIndex = commandLine.getOptionValue(SLICE_INDEX_OPTION) != null ?
                Integer.parseInt(commandLine.getOptionValue(SLICE_INDEX_OPTION)) :
                null;
    }

    /**
     * Take the arguments given at the command line and parse them to see everything is appropriate to the calling
     * of the Metabase API
     *
     * @param args arguments that are given from the command line in order to make calls to the Metabase API
     * @return CommandLine which will contain the values of the arguments given to the command line
     */
    private CommandLine parseArgumentsGivenAsParameters(String[] args) {
        Options options = createOptionForMenu();

        CommandLineParser parser = new DefaultParser();
        CommandLine commandLine = null;
        try {
            commandLine = parser.parse(options, args);
        } catch (ParseException e) {
            printHelp();
            System.exit(1);
        }

        return commandLine;
    }

    /**
     * Helper methods for the menu.
     * These can be ignored as they are meant for a better processing of the arguments from the command line.
     */
    public Options createOptionForMenu() {
        Option tokenOption = new Option("k", KEY_OPTION, true, null);
        tokenOption.setRequired(true);
        Option seqIdOption = new Option("s", SEQ_ID_OPTION, true, null);
        Option pauseMillisOption = new Option("p", PAUSE_MILLIS_OPTION, true, null);
        Option limitOption = new Option("l", LIMIT_OPTION, true, null);
        Option numSlicesOption = new Option("n", NUM_SLICES_OPTION, true, null);
        Option sliceIndexOption = new Option("i", SLICE_INDEX_OPTION, true, null);

        Options options = new Options();
        options.addOption(tokenOption);
        options.addOption(seqIdOption);
        options.addOption(pauseMillisOption);
        options.addOption(limitOption);
        options.addOption(numSlicesOption);
        options.addOption(sliceIndexOption);

        return options;
    }
    
    /**
     * if no arguments are passed to this class or the arguments were incorrect, this method will be called
     * to see exactly which are the arguments, the correct way of calling them and so forth
     */
    public void printHelp() {
        System.out.println(getHelpDescription());
    }

    private String getHelpDescription() {
        StringBuilder builder = new StringBuilder();
        builder.append("Usage commands: ");
        builder.append("\n\n");
        builder.append("-k | --key ").append("\t\t").append("Required: key (key) necessary to build the request URL to MB API");
        builder.append("\n");
        builder.append("-s | --sequenceId").append("\t\t").append("sequence ID in order to call sequentially the MB API");
        builder.append("\n");
        builder.append("-p | --pauseMillis").append("\t\t").append("pause between 2 calls to the MB API in milliseconds");
        builder.append("\n");
        builder.append("-l | --limit").append("\t\t\t").append("maximum of articles to get from MB API (default 500 | maximum 500)");
        builder.append("\n");
        builder.append("-n | --numSlices").append("\t\t\t").append("number of slices or clients that will be calling the MB API");
        builder.append("\n");
        builder.append("-i | --sliceIndex").append("\t\t\t").append("the slice this client is using for calling the MB API");
        builder.append("\n");

        return builder.toString();
    }

    public String getKey() {
        return key;
    }

    public void setKey(String key) {
        this.key = key;
    }

    public Long getSeqId() {
        return seqId;
    }

    public void setSeqId(Long seqId) {
        this.seqId = seqId;
    }

    public Integer getPauseMillis() {
        return pauseMillis;
    }

    public void setPauseMillis(Integer pauseMillis) {
        this.pauseMillis = pauseMillis;
    }

    public Integer getLimit() {
        return limit;
    }

    public void setLimit(Integer limit) {
        this.limit = limit;
    }

    public Integer getNumberOfSlices() {
        return numberOfSlices;
    }

    public void setNumberOfSlices(Integer numberOfSlices) {
        this.numberOfSlices = numberOfSlices;
    }

    public Integer getSliceIndex() {
        return sliceIndex;
    }

    public void setSliceIndex(Integer sliceIndex) {
        this.sliceIndex = sliceIndex;
    }

    public ObjectMapper getMapper() {
        return mapper;
    }

    public void setMapper(ObjectMapper mapper) {
        this.mapper = mapper;
    }

}
