%%%-------------------------------------------------------------------
%%% @author kreon
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Окт. 2016 13:10
%%%-------------------------------------------------------------------
-author("kreon").
-record(guestbook, {
  datetime :: integer(),
  name :: binary(),
  email :: binary(),
  message :: binary(),
  ip_address :: binary()
}).