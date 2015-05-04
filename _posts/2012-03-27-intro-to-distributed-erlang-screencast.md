---
layout: post
title: "Intro to Distributed Erlang Screencast"
description: "Simple look at distributed Erlang"
modified: 2012-03-27
tags: [erlang, debugging, screencast]
---

Here’s an introduction to distribution in Erlang. This screencast demonstrates creating
three Erlang nodes on a Windows box and one on a Linux box and then connecting them
using the one-liner “net_adm:ping” to form a mighty compute cluster.

Topics covered:

* Using [erl](http://www.erlang.org/doc/man/erl.html) to start an Erlang node (an instance of the Erlang runtime system).
* How to use [net_adm:ping](http://www.erlang.org/doc/man/net_adm.html#ping-1) to connect four Erlang nodes (three on Windows, one on Linux).
* Using [rpc:call](http://www.erlang.org/doc/man/rpc.html#call-4) to RickRoll a Linux box from an Erlang node running on a Windows box.
* Using [nl](http://www.erlang.org/doc/man/c.html#nl-1) to load (deploy) a module from one node to all connected nodes.

For a deeper dive into distributed Erlang here’s the [official reference](http://www.erlang.org/doc/reference_manual/distributed.html).

<iframe src="https://player.vimeo.com/video/39257971?title=0&amp;portrait=0" width="500" height="375" frameborder="0" webkitallowfullscreen mozallowfullscreen allowfullscreen></iframe> <p><a href="https://vimeo.com/39257971">Introduction to Distributed Erlang</a> from <a href="https://vimeo.com/user2962223">Bryan Hunter</a> on <a href="https://vimeo.com">Vimeo</a>.</p>
