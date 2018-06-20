# Dispatch-Proxy Docs

Dispatch-proxy is a SOCKS5/HTTP proxy that balances traffic between multiple internet connections.

## Pre-requisites
* Mac OS X 10.6+
* Windows 7+
* Node.JS >= 0.10.0

## Installation instructions

* Windows: [imgur album](http://imgur.com/a/0snis)
* Mac OS X: [imgur album](http://imgur.com/a/TSD5F)

## Help and Support
Please check out the documentation and FAQ first. We do not offer support but if you find a bug, you are more than welcome to open an issue.

### FAQ: ###
**Q: Can I run it on a router?**

**A:** It would be difficult to run this proxy on a wireless router, including a router configured as repeater because most of the routers on the market can only work at AP mode or Repeater mode. Thus a router generally saying cannot route packets through Ethernet and wireless connection to another AP at the same time.

We strongly encourage you to test running this project on a router which you have ssh access to. Please do let us know if any success!

**Q: I'm just curious, but how does this work?**

**A:** Dispatch-proxy balances traffic between connections. For instance, when you upload a youtube video, you establish a single HTTP connection between you and a youtube server. But if you were to upload two videos at the same time, you could potentially use both your interfaces.

The current load balancing algorithm is very simple and looks at the number of live connections owned by each interface to determine which interface to dispatch the next connection to (respecting priorities set via the @ syntax). In the future it will look at the total traffic of those connections.

At the moment the SOCKS proxy supports TCP CONNECT command, which means basically all TCP operations, but has no support for UDP BIND (UDP) yet.

**Q: Can I proxy a VPN by connecting to the same VPN server using multiple connections?**

**A:** Unfortunately it's not possible.

**Q: Can I share the proxy with others?**

**A:** If all devices are connected to the same network and upon correctly configured firewall rules, yes. However we do not provide any support at this.

## Contributing
So you like this project and want to make the world of internet even faster? That's awesome! In below we have provided some basic guidelines to help you contribute easier.

### Bug Report
Definition: A bug is a *demonstrable* problem that is caused by the code in the repository.

1. Use the GitHub issue search — check if the issue has already been reported. How to use search function? Check out this [guide](https://help.github.com/articles/using-search-to-filter-issues-and-pull-requests/).

2. Check if the issue has been fixed — try to reproduce it using the latest master or look for closed issues in the current milestone.

3. Isolate the problem — ideally create a reduced test case and a live example.

4. Include a screencast if relevant - Is your issue about a design or front end feature or bug? The most helpful thing in the world is if we can see what you're talking about. Use LICEcap to quickly and easily record a short screencast (24fps) and save it as an animated gif! Embed it directly into your GitHub issue.

5. Include as much info as possible! Use the Bug Report template below or click this link to start creating a bug report with the template automatically.

A good bug report shouldn't leave others needing to chase you up for more information. Be sure to include the details of your environment.

Here is a real example of a great bug report.


```sh
Short and descriptive example bug report title

### Issue Summary

A summary of the issue and the browser/OS environment in which it occurs.

### Steps to Reproduce
1. This is the first step
2. This is the second step, etc.

Any other info e.g. Why do you consider this to be a bug? What did you expect to happen instead?

### Technical details:
* Operation System: macOS 10.13.4
* Node Version: 4.4.7
* Dispatch-proxy Version: master (latest commit: a761de2079dca4df49567b1bddac492f25033985)
* Internet connections and local IP adresses
* Browser: Chrome 48.0.2564.109 on Mac OS X 10.10.4
```

### Feature Request
If you have ideas, feel free to open an issue and tell us all about it!

Request template:
```sh
Short and descriptive example feature request title

### Summary

A summary of the your idea and how it would work.

### Use case model
As... (a game streamer)
I want... (make use of two internet connections, both at 100 Mbps upload)
Because... (I need at least 120 Mbps to stream in 4k at 144 fps)
```

### Change Request
Change requests cover both architectural and functional changes to how Ghost works. If you have an idea for a new or different dependency, a refactor, or an improvement to a feature, etc - please be sure to:

1. Use the GitHub search and check someone else didn't get there first

2. Take a moment to think about the best way to make a case for, and explain what you're thinking as it's up to you to convince the project's leaders the change is worthwhile. Some questions to consider are:

* Is it really one idea or is it many?
* What problem are you solving?
* Why is what you are suggesting better than what's already there?
