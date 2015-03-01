---
layout: post
title: "Elixir Immutability"
description: ""
modified: 2015-02-14
tags: [elixir]
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
