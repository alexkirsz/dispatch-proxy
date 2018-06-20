dispatch-proxy
==============
A SOCKS5/HTTP proxy that balances traffic between multiple internet connections.

*Works on <b>Mac OS X</b>, <b>Windows</b> and <b>Linux</b>.*

**Detailed installation instructions:**

* Windows: [imgur album](http://imgur.com/a/0snis)
* Mac OS X: [imgur album](http://imgur.com/a/TSD5F)

Installation
------------
You'll need to have Node.JS >= 0.10.0 installed on your system.
```
$ npm install -g dispatch-proxy
```
To update:
```
$ npm update -g dispatch-proxy
```

Rationale
---------
You often find yourself with multiple unused internet connections, be it a 3G/4G mobile subscription or a free wifi hotspot, that your system wont let you use together with your main one.

For example, my residence provides me with a cabled and wireless internet access. Both are capped at 1,200kB/s download/upload speed, but they can simultaneously run at full speed. My mobile internet access also provides me with 400kB/s download/upload speed.

Combine all of these with `dispatch` and a threaded download manager and you get a 2,800kB/s download and upload speed limit, which is considerably better :)

Use-cases
---------
The possibilities are endless:

* combine as many Wi-Fi networks/Ethernet/3G/4G connections as you have access to in one big, load balanced connection,
* use it in conjunction with a threaded download manager, effectively combining multiple connections' speed in single file downloads,
* create two proxies, assign to each its own interface, and run two apps simultaneously that use a different interface (e.g. for balancing download/upload),
* create a hotspot proxy at home that connects through Ethernet and your 4G card for all your mobile devices,
* etc.

Quick start
-----------
The module provides a simple command-line utility called `dispatch`.
```
$ dispatch start
```
Start a SOCKS proxy server on `localhost:1080`. Simply add this address as a SOCKS proxy in your system settings and your traffic will be automatically balanced between all available internet connections.

Usage
-----
```
$ dispatch -h

  Usage: dispatch [options] [command]

  Commands:

    list                   list all available network interfaces
    start [options]        start a proxy server

  Options:

    -h, --help     output usage information
    -V, --version  output the version number
```
```
$ dispatch start -h

  Usage: start [options] [addresses]

  Options:

    -h, --help      output usage information
    -H, --host <h>  which host to accept connections from (defaults to localhost)
    -p, --port <p>  which port to listen to for connections (defaults to 8080 for HTTP proxy, 1080 for SOCKS proxy)
    --http          start an http proxy server
    --debug         log debug info in the console
```

Examples
--------
```
$ dispatch start --http
```
Start an HTTP proxy server listening on `localhost:8080`, dispatching connections to every non-internal IPv4 local addresses.
```
$ dispatch start 10.0.0.0 10.0.0.1
```
Dispatch connections only to local addresses `10.0.0.0` and `10.0.0.1`.
```
$ dispatch start 10.0.0.0@7 10.0.0.1@3
```
Dispatch connections to `10.0.0.0` 7 times out of 10 and to '10.0.0.1' 3 times out of 10.
