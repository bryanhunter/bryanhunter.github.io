-module(shadow).

-export([test]).

test(X) ->
	io:format("X is ~p", [X]),
	F = fun(X) -> io:format("fun X is ~p", [X]) end,
	f(50),
	io:format("X is ~p", [X]).

