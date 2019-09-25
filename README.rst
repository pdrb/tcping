tcping
=======

Ping hosts using tcp packets.

A Python version is also `available <https://github.com/pdrb/synping>`_.

Simple example::

    $ tcping example.org

    Pinging example.org 4 times on port 80:

    Reply from 93.184.216.34:80 time=1.72 ms
    Reply from 93.184.216.34:80 time=1.81 ms
    Reply from 93.184.216.34:80 time=1.75 ms
    Reply from 93.184.216.34:80 time=1.77 ms

    Statistics:
    --------------------------

    Host: example.org

    Sent: 4 packets
    Received: 4 packets
    Lost: 0 packets (0.00%)

    Min latency: 1.72 ms
    Max latency: 1.81 ms
    Average latency: 1.76 ms


Install
=======

Using nimble::

    $ nimble install

or

Using nim compiler::

    $ nim c -d:release tcping.nim

or

Using compiler to create a size optimized binary::

    $ nim c -d:release --opt:size --passL:-s tcping.nim

We can reduce the binary size even more using `upx <https://upx.github.io>`_::

    $ upx --best tcping

After these steps, the resulting binary size is 35K on my Linux server.


Usage
=====

::

    Usage: tcping host [options]

    ping hosts using tcp packets, e.g., 'tcping example.org'

    Options:
      -v, --version   show program's version number and exit
      -h, --help      show this help message and exit
      -t              ping host until stopped with 'control-c'
      -n:count        number of requests to send (default: 4)
      -p:port         port number to use (default: 80)
      -w:timeout      timeout in milliseconds to wait for reply
                      (default: 3000)


Examples
========

Ping host on port 80 (default)::

    $ tcping host

Ping host on port 22::

    $ tcping host -p:22

Ping host 10 times with 1 second timeout::

    $ tcping host -n:10 -w:1000

