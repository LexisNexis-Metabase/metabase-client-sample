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

use Getopt::Long;

require MetabaseApiTutorial;

# This is where the main functionality is:
#      - take the arguments from the command line
#      - construct a request url based on these arguments
#      - make call to the Metabase API
#      - receive the next sequenceId so we can make sequential calls to the Metabase API
#      (this is only to avoid receiving duplicate items)
#      - pause the next call (minimum 20 seconds) in order to not get denial of access from the Metabase API

$tutorial = MetabaseApiTutorial->new();

# This will take each arguments from the command line and set the fields so that we can easily work with the
# values from the command line
sub setFieldsFromArguments {
    GetOptions(
        'key=s'    => \$key,
        'hostName=s'    => \$hostName,
        'sequenceId=s'  => \$sequenceId,
        'pauseMillis=s' => \$pauseMillis,
        'limit=s'       => \$limit
    );

    $tutorial->key($key);
    $tutorial->hostName((!($hostName eq "")) ? $hostName : $tutorial->DEFAULT_MB_HOSTNAME);
    $tutorial->sequenceId((!($sequenceId eq "")) ? $sequenceId : undef);
    $tutorial->pauseMillis((!($pauseMillis eq ""))? $pauseMillis : $tutorial->DEFAULT_PAUSE_MILLIS);
    $tutorial->limit((!($limit eq "")) ? $limit : undef);
}

# Pause for how long we set the pauseMillis to be
sub sleepBetweenCalls {
     print "Sleeping for " . $tutorial->pauseMillis() . " milliseconds\n";
     sleep ($tutorial->pauseMillis / 1000);
     print "----------------------------------------------------------\n";
}

sub main {
    &setFieldsFromArguments;

    for ( ; ; ) {

        # make a call to the Metabase API with the given fields.
        # this will return the next sequenceId in order to know from where to start for the next call
        # (this will avoid getting duplicates)

        $nextSequenceId = $tutorial->callMetabaseApi(
            $tutorial->key(), $tutorial->hostName(),
            $tutorial->sequenceId(),    $tutorial->limit()
        );

        # set the sequenceId with the next sequenceId received from the InputStream
        
        $tutorial->sequenceId($nextSequenceId);

        &sleepBetweenCalls;
    }
}

&main;
