#!/usr/bin/env bash

################################################################################
# Help                                                                         #
################################################################################
Help()
{
    # Display help
    echo "This script runs Screaming Frog to crawl a site."
    echo
    echo "Syntax: scriptTemplate [-h|u|o|s]"
    echo "options:"
    echo "c     Clean up results after compression, if compressing, and uploading."
    echo "d     Shutdown after script completion."
    echo "h     Print this Help."
    echo "o     Output folder for crawl results.  Default: crawl-data/"
    echo "p     Project name.  Default: screamingfrog"
    echo "s     Screaming Frog settings/config file.  Default: None"
    echo "u     URL of site root.  Default: https://www.theretrofitsource.com/"
    echo "z     Zip/compress results before storing them in Google Cloud Bucket"
    echo
}

################################################################################
################################################################################
# Main program                                                                 #
################################################################################
################################################################################

# Set variable defaults
URL="https://www.theretrofitsource.com/"
OUTPUTARG="$HOME/crawl-data/"
PROJECT="screamingfrog"
SCREAMINGFROGCONFIGPATH=""
SHUTDOWNONCOMPLETE=0
CLEANUP=0
ZIPRESULTS=0


################################################################################
# Process the input options.  Add options as needed.                           #
################################################################################
# Get the options
while getopts ":cdho:p:s:u:z" option; do
    case $option in
	h) # display Help
	    Help
	    exit;;
	c) # Set Cleanup after compression/upload
	    CLEANUP=1;;
	s) # Set Config File
	    SCREAMINGFROGCONFIGPATH=$OPTARG;;
	d) # Set Shutdown on Complete
	    SHUTDOWNONCOMPLETE=1;;
	o) # Set Output Folder
	    OUTPUTARG=$OPTARG;;
	p) # Set Project Name
	    PROJECT=$OPTARG;;
	u) # Set URL
	    URL=$OPTARG;;
	z) # Set zip results
	    ZIPRESULTS=1;;
	\?) # Invalid option
	    echo "Error: invalid option"
	    exit;;
    esac
done

echo "url: $URL"
echo "settings/config: $SCREAMINGFROGCONFIGPATH"
echo "output dir: $OUTPUTARG"
echo "shutdown on complete: $SHUTDOWNONCOMPLETE"
echo "zip results: $ZIPRESULTS"
echo "cleanup: $CLEANUP"
echo "project: $PROJECT"

CONFIGARG=()

if [[ $SCREAMINGFROGCONFIGPATH != "" ]]; then
    CONFIGARG=( --config "${SCREAMINGFROGCONFIGPATH}" )
fi

TIMESTAMP=$(date +%F_%R)
echo "timestamp: $TIMESTAMP"

OUTPUTPARENTDIR="$OUTPUTARG/$TIMESTAMP/"
OUTPUTDIR="$OUTPUTARG/$TIMESTAMP/$PROJECT/"

echo "output parent: $OUTPUTPARENTDIR"
echo "output dir: $OUTPUTDIR"

if [[ ! -d $OUTPUTDIR ]]; then
    echo "Creating $OUTPUTDIR..."
    mkdir -p ${OUTPUTDIR}
    OUTPUTCREATERESULT=$?
    if [[ $OUTPUTCREATERESULT -ne 0 ]]; then
	echo "Error attempting to create dir $OUTPUTDIR: error code $OUTPUTCREATERESULT"
	exit $OUTPUTCREATERESULT
    fi
    echo "Created."
fi


echo "Starting Screaming Frog"

screamingfrogseospider --headless --save-crawl --timestamped-output --create-sitemap --crawl "$URL" --output-folder "$OUTPUTDIR" "${CONFIGARG[@]}"


if [[ $ZIPRESULTS -eq 1 ]]; then
    echo "Compressing results..."
    ZIPPATH=${OUTPUTDIR#$OUTPUTPARENTDIR}
    ZIPOUTPUT="$OUTPUTPARENTDIR/$PROJECT_$TIMESTAMP.tar.gz"
    tar -cvzf "$ZIPOUTPUT" -C "$OUTPUTPARENTDIR" "$ZIPPATH"
    ZIPSTATUS=$?
    if [[ $ZIPSTATUS -ne 0 ]]; then
	echo "Error attempting to compress $OUTPUTDIR"
	exit $ZIPSTATUS
    fi
    echo "Compressed."
fi

TOCOPY=$OUTPUTDIR

if [[ $ZIPRESULTS -eq 1 ]]; then
    TOCOPY=$ZIPOUTPUT
fi

echo "Copying Screaming Frog data at $TOCOPY to GCP bucket..."
gsutil cp -r "$TOCOPY" gs://dlg-frogger/

BUCKETCPSTATUS=$?

if [[ $BUCKETCPSTATUS -ne 0 ]]; then
    echo -e "Data copy to storage bucket exited with error code $BUCKETCPSTATUS"
    exit $BUCKETCPSTATUS
fi

echo "Copied."

if [[ $CLEANUP -eq 1 ]]; then
    echo "Cleaning up...."
    rm -rf "$OUTPUTPARENTDIR"

    CLEANUPSTATUS=$?

    if [[ $CLEANUPSTATUS -ne 0 ]]; then
	echo -e "Error while attempting to clean up data from local VM; error code $CLEANUPSTATUS"
	exit $CLEANUPSTATUS
    fi
fi


if [[ $SHUTDOWNONCOMPLETE -eq 1 ]]; then
    echo "Good night!"
    sudo shutdown -h +5
fi
