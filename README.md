autoscan
========

This is a small Raspberry Pi project to build a home scanning solution that nicely integrates with the Evernote cloud service.

The files in this workspace are expected to reside in /opt/autoscan.


Installation on a Raspberry Pi
------------------------------

On the Raspberri Pi the following packages must be installed for these scripts to work:

    $ sudo apt-get install ssmtp sane mailutils scanbuttond imagemagick


Check Scanner
-------------

Connect your scanner via USB with your Raspi and run

    $ lsusb

You should see something similar as on my Raspi:

    Bus 001 Device 002: ID 0424:9512 Standard Microsystems Corp. 
    Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
    Bus 001 Device 003: ID 0424:ec00 Standard Microsystems Corp. 
    Bus 001 Device 005: ID 03f0:1705 Hewlett-Packard ScanJet 5590  

The last line shows that the Raspi has found the scanner. In this case it is a HP ScanJet model. 

Test whether it is supported by the Sane driver:

    $ sudo scanimage -L
    device `hp5590:libusb:001:004' is a HP 5590 Workgroup scanner

You should see something similar. If not then you probably have a scanner that is not supported by Sane. Check [Sane Supported Scanners](http://www.sane-project.org/sane-supported-devices.html) to see what could be the issue.

Now check whether it is working correctly:

    $ sudo scanimage -A

It should show you some specific options your scanner might support in addition to the default values.

Now perform a test scan:

    $ sudo scanimage > /tmp/testscan.pnm

If everything works well we can go ahead in the configuration.


Setting up environment
----------------------

Create the sppol directory needed for the scanning process. Should not be in /tmp since in case of a tmpfs setup the space would be simply too small.

    $ sudo su
    # mkdir -p /var/spool/autoscan
    # chown saned /var/spool/autoscan

*Option 1*

Create the archive directory in case you would like to keep the generated PDF around.

    # mkdir /archive/autoscan
    # ln -sf /opt/autoscan/autoscan-postprocessing /opt/autoscan/autoscan-archive
    # crontab -e

Add the following into the crontab file for root:

    0   *  *   *   *     /opt/autoscan/autoscan-archive

*Option 2*

Alternatively you can just remove all files after they have been sent.

    # ln -sf /opt/autoscan/autoscan-postprocessing /opt/autoscan/autoscan-clean
    # crontab -e

Add the following into the crontab file for root:

    0   *  *   *   *     /opt/autoscan/autoscan-clean


Configuring scanbuttond
-----------------------

The file /etc/default/scanbuttond should must be modified to contain the following:

    # Set to yes to start scanbuttond
    RUN=yes
    # Set to the user scanbuttond should run as
    RUN_AS_USER=saned

Next perform the following:

    $ sudo ln -sf /opt/autoscan/buttonpressed.sh /etc/scanbuttond

(Re)start the scanbuttond:

    $ sudo /etc/init.d/scanbuttond restart


Configuring Email and Evernote:
-------------------------------

Configure your personal settings for autoscan:

    $ cd /opt/autoscan
    $ cp .autoscan-config.sample .autoscan-config
    $ nano .autoscan-config

Now change the email addresses and parameters to match your specific context.


Configuring Scanning Options:
-----------------------------

Now you need to configure what autoscan should do when pressing one of the scanner buttons.

Open buttonpressed.sh and make the necessary modifications that fit your needs. The script should be pretty easy to understand and you should add/modify the relevant parts in the lower part of the script.
