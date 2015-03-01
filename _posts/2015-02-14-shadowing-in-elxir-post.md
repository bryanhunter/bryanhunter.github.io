---
layout: post
title: "Elixir Immutability"
description: ""
modified: 2015-02-14
tags: [elixir]
noindex: true
---

The other day I received an email from a friend who is coming to Elixir from Ruby. The subject line
was "elixir immutability".

###The question
>I’m working throughout the elixir-lang.org tutorial and I cannot understand why the language
> is immutable AND I can keep re-assigning the different values to the same variable
> {% highlight elixir %}
 iex(21)> x = 1
 1
 iex(22)> x = 2
 2
 iex(23)> x
 2
{% endhighlight %} > I thought the definition of immutability is that you can’t do that!  What gives?

###My response

"Variables in Elixir are immutable like they are in Erlang. The thing you are seeing that looks like mutation (_and drives many Erlangers crazy_) is called variable shadowing ([more here](http://en.wikipedia.org/wiki/Variable_shadowing)). So in your shell example, you didn't actually change the value of x, you are just creating a new variable with the name "x" that had a different value and the old "x" is now out of scope. The old value is still there with nothing pointing at it (until it's garbage collected). The following sample uses an anonymous function to show what's happening a bit more clearly:

{% highlight elixir %}
iex(1)> x = fn () -> "First one" end
#Function<2.90072148/0 in :erl_eval.expr/5>
iex(2)> z =x
#Function<2.90072148/0 in :erl_eval.expr/5>
iex(3)> x =fn () -> "Second one" end
#Function<2.90072148/0 in :erl_eval.expr/5>
iex(4)> x.()
"Second one"
iex(5)> z.()
"First one"
iex(6)>
{% endhighlight %}

I'm not a fan of shadowing and don't use it, but it's not harmful. It doesn't create any of the shared-mutable-memory concurrency problems of non-functional languages. I suppose José Valim felt it would make people feel more at home if they were coming from OO languages."

##The reply
> And that explanation explains it perfectly. If you blog elixir, consider posting that because I didn’t “get it” from googling for it.

Done!


###Well not quite...

So why does shadowing drive many Erlangers crazy? Let's start of with how Erlang drives everyone else crazy. Shadowing was introduced in Elixir to avoid an ugly thing that happens in Erlang code when you need to perform a series of operations on some data. For example a dictionary...

{% highlight erlang %}

Eshell V6.3  (abort with ^G)
1> X = dict:new().
{dict, ...
2> X1 = dict:append("A",1,X).
{dict, ...
3> X2 = dict:append("B",2,X1).
{dict, ...
4> X3 = dict:append("C",3,X2).
{dict, ...
5>

{% endhighlight %}

Yes the intermediate variables `X`,`X1`,`X2`,`X3` are pretty darn ugly. It's not just ugly, it's potentially dangerous. Several times in Erlang, I've accidentally passed the wrong intermediate variable to a `dict` and as a result "lost a step" in the transformation. Unless you make an unfortunate combination of multiple goofs, you will get a compiler warning saying you have "usused variables". That compiler warning often saves the day. At any rate, everyoje agrees this code is ugly.

Shadowing in Elixir allows something more _"normal looking"_ (to a non-FP developer anyway).

{% highlight elixir %}
iex(1)> x = HashDict.new
#HashDict<[]>
iex(2)> x = Dict.put(x, "A", 1)
#HashDict<[{"A", 1}]>
iex(3)> x = Dict.put(x, "B", 2)
#HashDict<[{"A", 1}, {"B", 2}]>
iex(4)> x = Dict.put(x, "C", 3)
#HashDict<[{"A", 1}, {"B", 2}, {"C", 3}]>
iex(5)>
{% endhighlight %}

There we only have to keep up with one variable `x`. Seeing `x` rebound over-and-over is unsettling, and while not _as ugly_, this code is still _pretty ugly_. 

Elixir's lovely pipe foreward operator (`|>`) produces a much more elegent solution:

{% highlight elixir %}
iex(1)> x = HashDict.new |>
...(1)> Dict.put("A", 1) |>
...(1)> Dict.put("B", 2) |>
...(1)> Dict.put("C", 3)
#HashDict<[{"A", 1}, {"B", 2}, {"C", 3}]>
iex(2)>
{% endhighlight %}

The `|>` says take the output of the expression to the left and push it in as the first argument to the expression on the right. This feels functional; this makes me happy. With this I don't need/want the ability to bind `x` to different values. 

Ok, but where is the actual harm in shadowing? The thing that drives Erlangers crazy is not aesthetics (obviously) (rimshot) (cheapshot).

Here's the harm... here's what drives Erlangers crazy. Say we are Harry from the Harry Potter series. Ron Weasley is our buddy, and Voldemort will kill us on sight. We decide to code up a safety charm for our front door. We pick the ErlangVM because it is functional, declarative, and reliable. Here we go...

{% highlight elixir %}
iex(1)> friend = "Ron Weasley"
"Ron Weasley"
iex(2)> enemy = "Voldemort"
"Voldemort"
iex(3)> knocking_at_our_door = "Voldemort"
"Voldemort"
{% endhighlight %}

Yes, Ron is our friend and Voldemort is our enemy, and you-know-who is about to knock at our door. Our case statement should welcome our `friend` (i.e. "Ron Weasley") and curse/disarm our `enemy` (i.e. "Voldemort").

{% highlight elixir %}

iex(4)> our_response = case knocking_at_our_door do
...(4)>   friend -> "Come on inside, friend."
...(4)>   enemy -> "Expelliarmus!"
...(4)> end
"Come on inside, friend."

{% endhighlight %}

Wait! What the hell just happened?! Voldemort knocked at our door, and we say "Come on inside friend!" Let's check our variables (_and our underpants_) to see what happened...

{% highlight elixir %}

iex(5)> friend
"Ron Weasley"
iex(6)> enemy
"Voldemort"
iex(7)> knocking_at_our_door
"Voldemort"
iex(8)> our_response
"Come on inside, friend."

{% endhighlight %}

This is crazy. And we are dead. And this is by design. If we had written the follow code instead Harry Potter would have lived.

{% highlight elixir %}

iex(4)> our_response = case knocking_at_our_door do
...(4)>   ^friend -> "Come on inside, friend."
...(4)>   ^enemy -> "Expelliarmus!"
...(4)> end
"Explelliarmus!"

{% endhighlight %}

See the difference? Notice the `^friend` versus `friend` and `^enemy` versus `enemy`. The hat `^` says "use the last pinned value of this variable." Without the `^` the variable `friend` was't used as a guarding, declarative pattern match, it was used as a short-lived shadow variable that held whatever was passed in. That first clause would always match, and as soon as the case statement fell out of scope the evidence that for a tiny moment `friend` was `==` to `Voldemort`. That is subtle. That is dark magic. It is easy (especially for Erlangers who expect a match) to miss it. This will cause disasters, and the upside of the current behavious is hard to see. 

###Conclusion
Shadowing is not harmful in the same way that mutable variables are harmful. It's not going to jack up your parallel work. Shadowing is harmful in another way; it creates a pitfall and adds a diligence requirement (always a bad thing) when using pattern matching. This is an ugly wart on a  beautiful language. 


