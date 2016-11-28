%%%-------------------------------------------------------------------
%%% @author kreon
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Окт. 2016 4:15
%%%-------------------------------------------------------------------
-module(index_mod).
-author("kreon").
-include("/usr/lib/yaws/include/yaws_api.hrl").
%% API
-export([out/1]).

out(Arg) ->
  case rabbit:check_for_random(Arg) of
    ok -> out1(Arg);
    X -> X
  end.

out1(#arg{pathinfo = undefined}) ->
  [{ssi, "index.html", "%", []}];

out1(Arg) ->
  case lists:suffix(".html", Arg#arg.pathinfo) of
    true -> {ssi, Arg#arg.pathinfo, "%%", []};
    false -> {status, 404}
  end.

