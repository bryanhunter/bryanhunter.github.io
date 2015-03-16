---
layout: post
title: "Elixir Immutability"
description: ""
modified: 2015-02-14
tags: [elixir]
draft: true
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

I feel I need to go into _why_ shadowing drives many Erlangers crazy, but first let's start with how Erlang drives everyone else crazy. Shadowing was introduced in Elixir to avoid an ugly thing that happens in Erlang code when you need to perform a series of operations on some data. For example a dictionary in Erlang...

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

Yes the intermediate variables `X`,`X1`,`X2`,`X3` are pretty darn ugly. It's not just ugly; it's potentially dangerous. Several times in Erlang, I've accidentally passed the wrong intermediate variable to a `dict` and as a result "lost a step" in the transformation. Unless you make an unfortunate combination of multiple goofs, you will get a compiler warning saying you have "unused variables". That compiler warning often saves the day. At any rate, everyone agrees this code is ugly.

Now back to Elixir. Elixir's shadowing allows something more _"normal looking"_ (to a non-FP developer anyway).

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

There we only have to keep up with one variable `x`. While not _as ugly_, this code is still _pretty ugly_, and there is a better way. Elixir's lovely pipe-forward operator (`|>`) produces a much more elegant solution:

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

Here's the harm... Say we are Harry from the Harry Potter series. Ron Weasley is our buddy, and Voldemort will kill us on sight. We decide to code up a safety charm for our front door. We select Elixir and the ErlangVM because it is functional, declarative, and reliable. Here we go...

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
...(4)>   friend -> "Come on inside, #{friend}."
...(4)>   enemy -> "Expelliarmus!"
...(4)> end
"Come on inside, Voldemort."

{% endhighlight %}

Wait! What the hell just happened?! Voldemort knocked at our door, and we say, "Come on inside, Voldemort." Let's check our variables (_and our underpants_) to see what just happened...

{% highlight elixir %}

iex(5)> friend
"Ron Weasley"
iex(6)> enemy
"Voldemort"
iex(7)> knocking_at_our_door
"Voldemort"
iex(8)> our_response
"Come on inside, Voldemort."

{% endhighlight %}

This is crazy. And we are dead. And this is by design. If we had written the following code instead, Harry Potter would have lived.

{% highlight elixir %}

iex(4)> our_response = case knocking_at_our_door do
...(4)>   ^friend -> "Come on inside, #{friend}."
...(4)>   ^enemy -> "Expelliarmus!"
...(4)> end
"Explelliarmus!"

{% endhighlight %}

See the difference? Notice the `^friend` versus `friend` and `^enemy` versus `enemy`. The hat `^` says "use the last pinned value of this variable." Without the `^` the variable `friend` wasn't used as a guarding, declarative pattern match; instead it was used as a short-lived shadow variable that held whatever was passed in. That first clause would always match no matter what was passed in, and as soon as the case statement fell out of scope the only evidence that `friend` was ever equal to `Voldemort` is `our_response`. That is subtle; that is dark magic. It is easy (especially for Erlangers who expect a match) to miss it. This will cause problems, and the upside is hard to see. 

Another question: if we write this as a module, will the compiler save us with a helpful warning? Answer: maybe, or maybe not.

{% highlight elixir %}

defmodule KnockKnock do 
  def who_is_there do
    friend = "Ron Weasley"
    enemy = "Voldemort"
    knocking_at_our_door = "Voldemort"

    our_response = case knocking_at_our_door do
      friend -> "Come on inside, #{friend}."
      enemy -> "Expelliarmus!"
    end

    {friend,enemy,knocking_at_our_door,our_response}
  end
end
{% endhighlight %}

...and we compile
{% highlight elixir %}
iex(1)> c "knock_knock.ex"
knock_knock.ex:9: warning: variable enemy is unused
[KnockKnock]
{% endhighlight %}

Hmm... Mixed bag. There is no warning about `friend` because we (_pure-dumb-bad-luck_) happened to use the value in our response. We do get a compiler warning on line:9 because `enemy` is not used in that clause (_pure-dumb-good-luck_). That might have been enough to clue us in to the bug. If not, when we run... 

{% highlight elixir %}
iex(2)> KnockKnock.who_is_there
{"Ron Weasley", "Voldemort", "Voldemort", "Come on inside, Voldemort."}
iex(3)>
{% endhighlight %}

> Knock, knock. 
> Who's there?
> You know. 
> You-know-who? 

###Conclusion
Shadowing is not harmful in the same way that mutable variables are harmful. It's not going to jack up your parallel work. Shadowing does create a potential pitfall though, and it adds a diligence requirement (always a bad thing) when using pattern matching. 

This is an ugly wart on a beautiful language. 


