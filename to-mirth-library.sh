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

if [ "$1" != "-l" ] && [ "$1" != "-f" ]; then
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
    touch $OUTPUT_FILE;

    echo "<codeTemplate version=\"4.0.1\">
  <id>28ce17e5-b979-4273-b846-39b856ac22fa</id>
  <name>Custom Mirth Library</name>
  <revision>1</revision>
  <lastModified>
    <time>1652714434090</time>
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
  <properties class=\"com.mirth.connect.model.codetemplates.BasicCodeTemplateProperties\">" > $OUTPUT_FILE;

    # cycle on each function contained tin the input file


    FUNCTION_BODY="FALSE";
    while IFS= read -r LINE; do
        # inizio elemento funzione
        if [[ "$LINE" == "/**" ]]; then
           FUNCTION_BODY="TRUE";
           echo "<type>FUNCTION</type><code>" >> $OUTPUT_FILE;
        fi
        
        if [[ "$FUNCTION_BODY" == "TRUE" ]]; then
            echo "$LINE" >> $OUTPUT_FILE;
        fi

        if [[ "$LINE" == "}" ]] && [[ "$FUNCTION_BODY" == "TRUE" ]]; then
           FUNCTION_BODY="FALSE";
           echo "</code>" >> $OUTPUT_FILE;
        fi
    done < "$2"
    
    echo "</properties>
</codeTemplate>" >> $OUTPUT_FILE;
else 
    # script file transformation
    echo "";

    # const to channelMap
fi
