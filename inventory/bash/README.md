**Example bash scripts for ITxPT module inventory**
--------------------------------------
This example is based on ITxPT specification S02 and version 2.2.0

The intention is to show what a compliant module inventory dns-sd (txt record) output looks like, not to be a part of a complete production solution.


**History:**

It all started as a test of how hard is it to get a pc to announce itself as an ITxPT module.
A Raspberry-pi2B was flashed with ubuntu server 16.04, avahi and some tools were installed and the initial script was created
It was all ready and working in 40 minutes !!
After this minor adjustments were made and also aligned with ITxPT verson 2.1.1

The following txt key's are expected to be automatic populated by the script, other keys are read from the template file (that can be edited to add static information.

| key             | from version | Comment                           |
|-----------------|--------------|-----------------------------------|
| model           | 1.0.0        |                                   |
| softwareversion | 1.0.0        |                                   |
| serialnumber    | 1.0.0        |                                   |
| macaddress      | 1.0.0        |                                   |
| swvers          | 1.0.5        | follows the version of the script |
| manufacturer    | 1.0.5        | currently only on x86             |
| hardwareversion | 1.0.5        | currently only on x86             |
| hardwareversion | 1.0.6        | currently on x86 and moxa         |
| atdatetime      | 1.0.8        | a timestamp of the record         |

The script can be run from the command line, but needs to be run with sudo rights
To get a more consistent approatch, run it from crontab..

Ex:
copy the script and the template to:
/opt/inventory/
.. and make sure they are owned and kan be run by root

Use the command: sudo crontab -e
.. to edit the root crontab job list
.. add the line:
*/10 * * * * /opt/inventory/avahi_device-inventory.sh



Use commandline parameter -h or --help to se all options of the script.
.. make sure you point to the right ethernet interface !


See INSTALL.md for a complete instruction (TBD)

**Version history**

| Date       | Version | Description                                                                   |
|------------|---------|-------------------------------------------------------------------------------|
| 2021-10-13 | 1.0.4   | Initial publication, minor code cleanup from 1.0.0 and alignment to v2.1.1    |
| 2021-10-18 | 1.0.5   | added support for manufacturer and hardwareversion on x86                     |
| 2021-10-18 | 1.0.6   | added support for manufacturer and hardwareversion on moxa arm7l              |
| 2024-10-11 | 1.0.8   | added support for Rpi4 and ITxPT inventory ver. 2.2.0                         |

** Known issues:**
1. There is a delay in nn minutes in some cases before clients gets the latest update from the script. Most likely due to that toutch the .service file do not trigger a proper "flush cash" procedur before sending the update. A more correct way might be using Dbus.

2. All key's must have a value assigned, use the text "NA" instead of NULL (empty string). See examples in the service template file.
Faulty key values can make the message to be rejected by the daemon or even make avahi-daemon to die.. avahi.discovery is even more sensitive.

--------------------------------------------------------------

