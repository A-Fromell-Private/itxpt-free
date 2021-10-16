**Example bash scripts for ITxPT inventory**
--------------------------------------
This example is based on ITxPT specification S02 and version 2.1.1

The intention is to show what a compliant module inventory dns-sd (txt record) output looks like, not to be a part of a complete production solution.
The script also adds an additional key "update=" with a timestamp (when the record was generated) formatted according to ITxPT TR-001.

The script can be run from the command line, but needs to be run with sudo rights
To get a more consistent approatch, run it from crontab..

Use commandline parameter -h or --help to se all options.

See INSTALL.md for a complete instruction (TBD)

--------------------------------------
