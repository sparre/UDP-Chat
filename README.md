UDP Chat [1]
============

Experimental UDP-based chat application.

The repository only contains my old clone of "talk", implementing
character-by-character chat over UDP.


Usage
-----

    udp_talk <local port> <remote host> <remote port>

If you want to chat with a user on "remote.host.example" and you (over
another channel) have agreed to use port 8877, you run:

    udp_talk 8877 remote.host.example 8877

And your friend runs:

    udp_talk 8877 your.host.example 8877

And then it is just a matter of typing...

If you want to play with it on a single machine, open two terminals, and
run the program in both, but with the port numbers reversed:

    udp_talk 8877 localhost 7788

    udp_talk 7788 localhost 8877

Once both instances are running, you're ready to chat.

You are welcome to see if I'm awake:

    udp_talk 10123 www.jacob-sparre.dk 10123


Build dependencies
------------------

+ Bash
* GNU Parallel
* GNAT
* Mercurial (hg)
* FLORIST (or another POSIX Ada API implementation)


Installing
----------

```
    make install
```

Builds and tests the executable before installing it in
"${DESTDIR}${PREFIX}/bin" (where "${PREFIX}" defaults to "${HOME}").

Installing may also work on Windows, if you substitute "OS_VERSION=unix" with
"OS_VERSION=windows".


Testing
-------

```
    make test
```


Building
--------

```
    make build
```


Links
-----

If you want to find free Ada tools or libraries AdaIC [2] is an excellent
starting point.  You can also take a look at my other source text
repositories [3] or my web site [4].

[1] Source text repository:
    http://repositories.jacob-sparre.dk/udp-chat

[2] Free Ada Tools and Libraries:
    http://www.adaic.org/ada-resources/tools-libraries/

[3] My repositories on Bitbucket:
    http://repositories.jacob-sparre.dk/

[4] My web site:
    http://www.jacob-sparre.dk/

