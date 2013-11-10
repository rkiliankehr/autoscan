autoscan
========

This is a small Raspberry Pi project to build a home scanning solution that nicely integrates with the Evernote cloud service.

It builds upon great project descriptions and blogs from other people and I have tried to make it simple(r) for others to consume that prior art such as

* http://johannesnews.blogspot.de/2013/02/scan-to-email-with-only-one-buttonpress.html
* http://eduardoluis.com/raspberry-pi-and-usb-network-scanner/
* http://brainofanape.blogspot.de/2012/11/scanning-to-cloud-fujitsu-scansnap.html

Main differences compared to the others is:

* make use of the scanner buttons instead of additional GPIO connected buttons;
* scan and then immediately perform the asynchronous post-processing steps such as PDF creation and sending to Evernote;
* increase robustness of the overall solution;
* avoid setting up a full-fledged email system on the raspi.

Thanks for the great prior work of the colleages listed above.


Install necessary packages on a the Pi
--------------------------------------

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


Set up environment
------------------

The files in this workspace are expected to reside in `/opt/autoscan`.

    $ sudo mkdir -p /opt/autoscan
    $ cd /opt
    $ sudo chown pi autoscan
    $ chgrp pi autoscan
    $ git clone git@github.com:rkiliankehr/autoscan.git

Create the sppol directory needed for the scanning process. Should not be in `/tmp` since in case of a tmpfs setup the space would be simply too small.

    $ sudo mkdir -p /var/spool/autoscan
    $ sudo chown saned /var/spool/autoscan


Configure scanbuttond
---------------------

The file `/etc/default/scanbuttond` must be modified to contain the following configuration:

    # Set to yes to start scanbuttond
    RUN=yes
    # Set to the user scanbuttond should run as
    RUN_AS_USER=saned

Next perform the following:

    $ sudo ln -sf /opt/autoscan/buttonpressed.sh /etc/scanbuttond

(Re)start the `scanbuttond` daemon:

    $ sudo /etc/init.d/scanbuttond restart


Configure Email and Evernote
----------------------------

The mechanism here creates new Evernote notes via the email method. This is certainly suboptimal and the creation via the Evernote developer API would be much more desirable. However, setting this up for you would also be more complex and that's why I currently stick with the email approach.

Configure your personal settings for autoscan:

    $ cd /opt/autoscan
    $ cp .autoscan-config.sample .autoscan-config
    $ nano .autoscan-config

Now change the email addresses and parameters to match your specific context. If you don't know the email address of your account then check out your  Account Info section in Evernote.


Configure Scanning Options
--------------------------

Now you need to configure what autoscan should do when pressing one of the scanner buttons.

Open `buttonpressed.sh` and make the necessary modifications that fit your needs. The script should be pretty easy to understand and you should add/modify the relevant parts in the lower part of the script.

In the script here you see that three buttons are currently configured as follows:

* Flatbed scan, single document, grayscale, 300 dpi
* Flatbed scan, single document, colour, 200 dpi
* ADF (feeder) scan, multiple documents, grayscale, 300 dpi

Colour scans with 300 dpi tend to become pretty large and require more processing time (conversion, email send, evernote sync time) they should be used with care. 


Configure Postprocessing
------------------------

Currently there are two possible postprocessing mechanisms:

* The first one moves the generated PDFs into a dedicated archives folder and removes all other files.
* The second one just removes all files for all completed jobs.

Thus, jobs which could not be finished will remain such that some later sending could be performed. 

We use a `cron` job for user `root` for performing the post processing. 

*Option 1*

Create the archive directory in case you would like to keep the generated PDF around.

    # sudo - su
    # mkdir /archive/autoscan
    # ln -sf /opt/autoscan/autoscan-postprocessing /opt/autoscan/autoscan-archive
    # crontab -e

Add the following into the crontab file for root:

    0  *  *  *  *  /opt/autoscan/autoscan-archive

*Option 2*

Alternatively you can just remove all files after they have been sent.

    # sudo - su
    # ln -sf /opt/autoscan/autoscan-postprocessing /opt/autoscan/autoscan-clean
    # crontab -e

Add the following into the crontab file for root:

    0  *  *  *  *  /opt/autoscan/autoscan-clean


Todo
----

Lots of things could be improved. 