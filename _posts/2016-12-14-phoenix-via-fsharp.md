---
layout: post
title: "Phoenix Channels via F#"
description: "My 2016 F# Advent calendar post"
modified: 2016-12-27
tags: [elixir, fsharp]
draft: true
noindex: true
---
## Premise

I'm an FP cheerleader, and I enjoy both Elixir and F#. Both are lovely, but they are very different (different VMs, different priorities, different sweet-spots). This is what I look for when evaluating my toolbox each year. A set of distinct complementary tools is much better than a box full of hammers.

I'm hopeful this [F# Advent Calendar](https://sergeytihon.wordpress.com/2016/10/23/f-advent-calendar-in-english-2016/) post will spark ideas on how you might use the two languages together. My goal isn't to present a polished, client library, but more to ~~trick~~ inspire you to write one.

## Background on Phoenix Channels
If you are unfamiliar with Elixir..._[info info info]_... Phoenix is the primary web framework for Elixir. ..._[info info info]_... Channels is a mechanism for topic based communication.

### Prerequisites
We're going to need:
* F#
* Elixir
* A Phoenix application to test against

### Setting up a sample Phoenix app
To see everything in action we will use a sample Phoenix chat application was written by Chris McCord (the creator of Phoenix). You can find the sample here:
// https://github.com/chrismccord/phoenix_chat_example)


## Playing with Channels from the F# REPL

Phoenix channels supports pluggable transports. The two in-the-box transports are WebSockets and LongPolling. In our F# client we will talk to Phoenix via WebSockets and we will piggyback on [WebSocketSharp](https://www.nuget.org/packages/WebSocketSharp) to handle to communication bits that aren't specific Phoenix channels.

{% highlight OCaml %}
// #r @"..\packages\WebSocketSharp.1.0.3-rc11\lib\websocket-sharp.dll"
open WebSocketSharp
{% endhighlight %}

Next we will create a `WebSocket` pointing to our Phoenix channel route.

{% highlight OCaml %}

let ws = new WebSocket("ws://localhost:4000/socket/websocket")

{% endhighlight %}

So we're not flying blind we will hook up logging to the WebSocketSharp events.

{% highlight OCaml %}

let log msg = printfn "%s" msg

ws.OnOpen.Add(fun args -> log "Open")
ws.OnClose.Add(fun args -> log "Close")
ws.OnMessage.Add(fun args -> log("Msg: " + args.Data))
ws.OnError.Add(fun args -> log("Error: " + args.Message))

{% endhighlight %}

Next we will connect.

{% highlight OCaml %}
ws.Connect()
{% endhighlight %}

Now we get to the first Phoenix-specific bits. We will join a channel called "rooms:lobby"
{% highlight OCaml %}

ws.Send("{\"ref\":\"1\", \"event\":\"phx_join\", \"topic\":\"rooms:lobby\",
\"payload\":{\"user\":\"boo\"}}")

{% endhighlight %}

Other users will see that we have joined the channel, and we will see logged (from `ws.OnMessage` above) any messages from other users.

{% highlight OCaml %}

ws.Send("{\"ref\":\"2\", \"event\":\"new:msg\", \"topic\":\"rooms:lobby\",
\"payload\":{\"user\":\"boo\", \"body\":\"howdy\"}}")

ws.Send("{\"ref\":\"3\", \"event\":\"new:msg\", \"topic\":\"rooms:lobby\",
 \"payload\":{\"user\":\"boo\", \"body\":\"Woohoo!\"}}")

{% endhighlight %}

All good things must come to an end, so here's how we leave the channel.
{% highlight OCaml %}

ws.Send("{\"ref\":\"4\", \"event\":\"phx_leave\", \"topic\":\"rooms:lobby\",
\"payload\":{\"user\":\"boo\"}}")

{% endhighlight %}

## A bit less metal, please

So we have hacked our way into the party. None of the other members in the channel suspect we're blasting raw messages. That's fun, but it won't win any design prizes. How do we go from bare metal to something that feels nice, idiomatic, and functional.

We could take a peek at Scott Wlaschin's "[13 Ways of Looking at a Turtle](http://fsharpforfunandprofit.com/posts/13-ways-of-looking-at-a-turtle/)" series and try out different APIs (I highly recommend that). Since Elixir is based on the Actor model, I like the idea of "[Way #5: an API in front of an agent](https://fsharpforfunandprofit.com/posts/13-ways-of-looking-at-a-turtle/#way5)". Lets see how we it all maps.

## Phoenix channels via an F# Agent-backed API
First, what does our API need to let us do?
* _Connect to a Socket_: We will create a socket connection by pointing our websocket library at a Phoenix endpoint (Uri).
* _Join Channel_: Phoenix channels are topic based conversations that many users can join simultaneously. From our single socket connection we can join many channels.
* _Receive_: After we join a channel we want to be able to lurk and hear what's being sent on the channel.
* _Send_: We also want the ability to send our own messages to other to the channel.
* _Leave Channel_: When we are no longer interested in sending or receiving messages on a given topic we should be able to leave that channel without affecting our other channels.
* _Diconnect the socket_: When the party comes to an end we don't want F# to be "that guy" who doesn't know it's time to leave.
