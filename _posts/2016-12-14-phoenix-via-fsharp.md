---
layout: post
title: "Phoenix Channels via F#"
description: "My 2016 F# Advent calendar post"
modified: 2016-12-27
tags: [elixir, fsharp]
draft: true
noindex: true
---

I'm a fan of both Elixir and F#. I'm hopeful this F# Advent Calendar post will spark ideas on how you might use the two languages together.

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

## Playing with Channels the REPL

Phoenix channels supports pluggable transports. The two in-the-box transports are WebSockets and LongPolling. In our F# client we will talk to Phoenix via WebSockets and we will piggyback on [WebSocketSharp](https://www.nuget.org/packages/WebSocketSharp) to handle to communication bits that aren't specific Phoenix channels.

{% highlight fsharp %}
// #r @"..\packages\WebSocketSharp.1.0.3-rc11\lib\websocket-sharp.dll"
open WebSocketSharp
{% endhighlight %}

Next we will create a `WebSocket` pointing to our Phoenix channel route.

{% highlight fsharp %}

let ws = new WebSocket("ws://localhost:4000/socket/websocket")

{% endhighlight %}

So we're not flying blind we will hook up logging to the WebSocketSharp events.

{% highlight fsharp %}

let log msg = printfn "%s" msg

ws.OnOpen.Add(fun args -> log "Open")
ws.OnClose.Add(fun args -> log "Close")
ws.OnMessage.Add(fun args -> log("Msg: " + args.Data))
ws.OnError.Add(fun args -> log("Error: " + args.Message))

{% endhighlight %}

Next we will connect.

{% highlight fsharp %}
ws.Connect()
{% endhighlight %}

Now we get to the first Phoenix-specific bits. We will join a channel called "rooms:lobby"
{% highlight fsharp %}

ws.Send("{\"ref\":\"1\", \"event\":\"phx_join\", \"topic\":\"rooms:lobby\",
\"payload\":{\"user\":\"boo\"}}")

{% endhighlight %}

Other users will see that we have joined the channel, and we will see logged (from `ws.OnMessage` above) any messages from other users.

{% highlight fsharp %}


ws.Send("{\"ref\":\"2\", \"event\":\"new:msg\", \"topic\":\"rooms:lobby\",
\"payload\":{\"user\":\"boo\", \"body\":\"howdy\"}}")

ws.Send("{\"ref\":\"3\", \"event\":\"new:msg\", \"topic\":\"rooms:lobby\",
 \"payload\":{\"user\":\"boo\", \"body\":\"Woohoo!\"}}")

{% endhighlight %}

All good things must come to an end, so here's how we leave the channel.
{% highlight fsharp %}

ws.Send("{\"ref\":\"4\", \"event\":\"phx_leave\", \"topic\":\"rooms:lobby\",
\"payload\":{\"user\":\"boo\"}}")

{% endhighlight %}

## A bit less metal, please

So we have hacked our way into the party. None of the other members in the channel would suspect we're blasting raw messages. Neat, but not very declarative.

So how do we go from bare metal to something that feels nice and F#-y?

We could take a peek at Scott Wlaschin's "[13 Ways of Looking at a Turtle](http://fsharpforfunandprofit.com/posts/13-ways-of-looking-at-a-turtle/)" series and try on different APIs. Since Elixir is based on the Actor model, "[Way #5: an API in front of an agent](https://fsharpforfunandprofit.com/posts/13-ways-of-looking-at-a-turtle/#way5)" feel like natural fit to me.

## Phoenix channels via an F# Agent-backed API
What are our goals?
* Sockets: We want to connect to a Phoenix endpoint.
* Channels: Join topic based conversations called channels.
* Receive: once we have joined a channel we want to be able to listen to what's being said on the channel.
* Send: we also want to send messages to other clients who are on the channel
* Diconnect: when the party comes to an end we don't want F# to be "that guy" who doesn't know it's time to leave.

Our goals could include
