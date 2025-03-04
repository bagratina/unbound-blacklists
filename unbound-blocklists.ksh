#!/bin/ksh
#
# Using blocklist to enable hosts blocking in unbound(8)
#
PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin"

blocklists[0]="https://small.oisd.nl/unbound"
blocklists[1]="https://nsfw-small.oisd.nl/unbound"

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

function removeTmpFile {
	rm -f $tmpfile
}

function createLocalZoneFile {
	sortTmpFile > $unboundconf && removeTmpFile
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
