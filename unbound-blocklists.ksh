#!/bin/ksh
#
# Using blocklist to enable hosts blocking in unbound(8)
# Based on https://www.tumfatig.net/2019/blocking-ads-using-unbound8-on-openbsd/
#
# Add new crontab(5) job for the blocklists maintenance:
#
#	0-5 */6 * * * -s /usr/local/bin/unbound-blocklists.sh
#
PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

blocklists[0]="https://blocklistproject.github.io/Lists/alt-version/ads-nl.txt"
blocklists[1]="https://blocklistproject.github.io/Lists/alt-version/porn-nl.txt"

tmpfile="$(mktemp)"
unboundconf="/var/unbound/etc/unbound-blocked.conf"

function download {
	ftp -VMo- $1
}

function removeComments {
	sed -e 's/#.*$//'
}

function removeEmptyLines {
	grep -v "^[[:space:]]*$"
}

function addBlocklistContent {
	download $1 | removeComments | removeEmptyLines >> $tmpfile
}

function processBlocklists {
	for blocklist in "${blocklists[@]}"; do
		addBlocklistContent $blocklist
	done
}

function sortTmpFile {
	sort -fu $tmpfile
}

function transform {
	awk '{
		print "local-zone: \"" $1 "\" inform_redirect"
		print "local-data: \"" $1 " A 0.0.0.0\""
	}'
}

function removeTmpFile {
	rm -f $tmpfile
}

function createLocalZoneFile {
	sortTmpFile | transform > $unboundconf && removeTmpFile
}

function checkUnboundConfig {
	doas -u _unbound unbound-checkconf 1>/dev/null
}

function reloadUnboundConfig {
	doas -u _unbound unbound-control reload 1>/dev/null
}

#Begin
processBlocklists
createLocalZoneFile
checkUnboundConfig && reloadUnboundConfig

exit 0
