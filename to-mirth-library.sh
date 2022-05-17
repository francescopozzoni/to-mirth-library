#!/bin/bash
# Francesco Pozzoni, 20220516

# usage function
function usage {
   cat << EOF
USAGE: to-mirth-library.sh options input output

options:
  -l to perform a transformation of a library file
  -s to perform a tranformation of a script file

input:
  the file to transform

output:
  the output filename, the extension will be appended accordingly
EOF
   exit 1
}

# checks on input files
if [ $# -ne 3 ]; then
    echo "ERROR: Wrong number of arguments.";
    usage;
fi

if [ "$1" != "-l" ] && [ "$1" != "-s" ]; then
    echo "ERROR: Unknown flag options.";
    usage;
fi

if [ ! -f "$2" ]; then
    echo "ERROR: Input file \"$2\" doesn't exists.";
    usage;
fi

if [ "$1" == "-l" ]; then
    # library file transformation
    OUTPUT_FILE="$3.xml";
    ID_RADIX="2578b4c3-09a2-42bd-8fd7-7fef94ec";
    touch $OUTPUT_FILE;

    # reading library name
    echo "Insert library name (default \"Common utils library\"):";
    read LIBRARY_NAME;

    if [ "$LIBRARY_NAME" == "" ]; then
        LIBRARY_NAME="Common utils library";
    fi

    # pre processing input file by removing not recognised charachters
    cp $2 "temp";

    gsed -i "s/&/\&amp\;/g" temp;
    gsed -i "s/'/\&apos\;/g" temp;
    gsed -i "s/</\&lt\;/g" temp;
    gsed -i "s/>/\&gt\;/g" temp;

    # initializing output file
    echo '<codeTemplateLibrary version="4.0.1">
  <id>3e34d144-28d1-48ab-8517-78485a289c80</id>
  <name>'"$LIBRARY_NAME"'</name>
  <revision>1</revision>
  <lastModified>
    <time>1652714433902</time>
    <timezone>America/Los_Angeles</timezone>
  </lastModified>
  <description></description>
  <includeNewChannels>false</includeNewChannels>
  <enabledChannelIds>
    <string>7eacbb09-6f3a-4c33-9030-24ef43234a7f</string>
  </enabledChannelIds>
  <disabledChannelIds/>
  <codeTemplates>' > $OUTPUT_FILE;

    # cycle on each function contained in the temp file
    FUNCTION_BODY="FALSE";
    
    while IFS= read -r LINE; do
        # inizio elemento funzione
        if [[ "$LINE" == "/**" ]]; then
            INSIDE_FUNCTION_BODY="TRUE";
            FUNCTION="";
            FUNCTION_NAME="";
        fi

        # adding each line to the function cycle variable
        if [[ "$INSIDE_FUNCTION_BODY" == "TRUE" ]] && [[ "$FUNCTION" == "" ]];
        then
            FUNCTION="$LINE";
        fi
        if [[ "$INSIDE_FUNCTION_BODY" == "TRUE" ]] && [[ "$FUNCTION" != "" ]];
        then
            FUNCTION="$FUNCTION
$LINE";
        fi

        # get function name
        if [[ "$LINE" =~ ^function.*\(.* ]]; then
            FUNCTION_NAME=$(gsed 's/^function \(.*\)(.*/\1/' <<< "$LINE");
        fi
        
        # inserting the line
        if [[ "$LINE" == "}" ]] && [[ "$INSIDE_FUNCTION_BODY" == "TRUE" ]]; then
            INSIDE_FUNCTION_BODY="FALSE";
            PSEUDOID=$((1 + RANDOM % 1000));
            printf '<codeTemplate version="4.0.1">
      <id>'"$ID_RADIX""$PSEUDOID"'f</id>
      <name>'"$FUNCTION_NAME"'</name>
      <revision>3</revision>
      <lastModified>
        <time>1652714433959</time>
        <timezone>America/Los_Angeles</timezone>
      </lastModified>
      <contextSet>
        <delegate>
          <contextType>DESTINATION_RESPONSE_TRANSFORMER</contextType>
          <contextType>SOURCE_RECEIVER</contextType>
          <contextType>DESTINATION_FILTER_TRANSFORMER</contextType>
          <contextType>SOURCE_FILTER_TRANSFORMER</contextType>
          <contextType>DESTINATION_DISPATCHER</contextType>
        </delegate>
      </contextSet>
      <properties class="com.mirth.connect.model.codetemplates.BasicCodeTemplateProperties">
        <type>FUNCTION</type>
        <code>' >> $OUTPUT_FILE;
            echo "$FUNCTION" >> $OUTPUT_FILE;
            echo "</code>
      </properties>
    </codeTemplate>" >> $OUTPUT_FILE;
        fi
    done < temp;

    # closing xml
    echo "  </codeTemplates>
</codeTemplateLibrary>" >> $OUTPUT_FILE;

    # cleaning temp file
    rm temp;
else 
    # script file transformation
    OUTPUT_FILE="$3-output.js";

    # copy the input file
    \cp $2 "$OUTPUT_FILE";

    # apply mirth changes

    # declaration of const automagically become insertion in the globalChannelMap
    gsed -i "s/const \(.*\) = \('.*'\)/globalChannelMap.put('\1',\2)/g" "$OUTPUT_FILE";

    # log variable is read and modified directly from the globalChannelMap
    perl -i -p0e "s/var log = ('.*?');/channelMap.put('log', \\$\('log'\) + \1);/gs" "$OUTPUT_FILE";
    perl -i -p0e "s/log \+= ('.*?');/channelMap.put('log', \\$\('log'\) + \1);/gs" "$OUTPUT_FILE";
    perl -i -p0e "s/log \+= ('.*');/channelMap.put('log', \\$\('log'\) + \1);/gs" "$OUTPUT_FILE";

    # error variable is read from the globalChannelMap and stored in the 
    if ggrep -q 'var err;' "$OUTPUT_FILE"; then
        perl -i -p0e "s/var err;/channelMap.put('err', false;/s" "$OUTPUT_FILE";
        echo "channelMap.put('err', err)" >> $OUTPUT_FILE;
    fi 
fi
