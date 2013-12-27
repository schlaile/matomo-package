#!/bin/bash

if [ -z "$1" ] || [ ! -f "debian/changelog" ]
then
	exit 1
fi

if [ ! -z "$2" ] && [ "$2" = "--test" ]
then
	echo "Test mode enabled, not adding entries to debian/changelog"
	TEST_MODE=1
else
	TEST_MODE=0
fi

CHANGELOG_URL=$(wget -O - -q 'http://piwik.org/changelog/' | grep "Piwik $1" | sed 's/.*<a href=\([^>]*\).*/\1/' | sed -e 's/"//g' -e "s/'//g")

echo "changelog url at $CHANGELOG_URL"

if [ -z "$(echo $CHANGELOG_URL | grep -i http)" ]
then
	echo "not a valid url"
	exit 2
fi

wget -O - -q "$CHANGELOG_URL" | \
	sed -n "/List of.*in Piwik $1.*>$/,/<\/div>/p;" | \
	grep 'dev.piwik.org/trac/ticket' | \
	sed -e :a -e 's/<[^>]*>//g;/</N;//ba' | \
	recode HTML..UTF-8 | recode UTF-8..ascii | \
	sed 's/\^A//g' | \
	sed -r 's/^(#[0-9]+)([ ]+)(.*)/\3 (Closes: \1)/g' | while read LINE
do
	if [ "$TEST_MODE" -eq "1" ]
	then
		echo "  * ${LINE}"
	else
		debchange --changelog debian/changelog -a -- ${LINE}
	fi
done