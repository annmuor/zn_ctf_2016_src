%%%-------------------------------------------------------------------
%%% @author kreon
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Окт. 2016 1:04
%%%-------------------------------------------------------------------
-module(rabbit_app).
-author("kreon").

-behaviour(application).

%% Application callbacks
-export([start/2,
  stop/1]).

start(_StartType, _StartArgs) ->
  case rabbit_sup:start_link() of
    {ok, Pid} ->
      {ok, Pid};
    Error ->
      Error
  end.


stop(_State) ->
  ok.