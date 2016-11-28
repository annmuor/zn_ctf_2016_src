%%%-------------------------------------------------------------------
%%% @author kreon
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Окт. 2016 1:56
%%%-------------------------------------------------------------------
-module(rabbit_sup).
-author("kreon").

-behaviour(supervisor).

%% API
-export([start_link/0]).

%% Supervisor callbacks
-export([init/1]).

-define(SERVER, ?MODULE).

%%%===================================================================
%%% API functions
%%%===================================================================

%%--------------------------------------------------------------------
%% @doc
%% Starts the supervisor
%%
%% @end
%%--------------------------------------------------------------------
-spec(start_link() ->
  {ok, Pid :: pid()} | ignore | {error, Reason :: term()}).
start_link() ->
  supervisor:start_link({local, ?SERVER}, ?MODULE, []).


do_init(List) ->
  do_init(List, []).

do_init([], Results) ->
  Results;

do_init([H | T], Results) ->
  do_init(T, Results ++ [{H, {H, start_link, []}, permanent, 2000, worker, []}]).

init([]) ->
  Modules = [calculator, flag, guestbook],
  {ok, {{one_for_one, 1000, 3600}, do_init(Modules)}}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
