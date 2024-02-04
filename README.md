# Using blocklist to enable hosts blocking in unbound(8)
Based on https://www.tumfatig.net/2019/blocking-ads-using-unbound8-on-openbsd/

## Add new crontab(5) job for the blocklists maintenance:

```
0-5 */6 * * * -s /usr/local/bin/unbound-blocklists.sh
```
