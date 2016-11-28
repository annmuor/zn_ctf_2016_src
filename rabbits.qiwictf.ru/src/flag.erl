%%%-------------------------------------------------------------------
%%% @author kreon
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. Окт. 2016 21:03
%%%-------------------------------------------------------------------
-module(flag).
-author("kreon").

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {}).
-record(flags, {
  name :: string(),
  fake :: boolean(),
  value :: string(),
  algo :: string()
}).

start_link() ->
  mnesia:create_schema([node()]),
  mnesia:start(),
  mnesia_create_tables_if_needed(),
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

init([]) ->
  {ok, #state{}}.

handle_call(_Request, _From, State) ->
  {reply, ok, State}.

handle_cast(_Request, State) ->
  {noreply, State}.

handle_info(_Info, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

%%%===================================================================
%%% Internal functions
%%%===================================================================
mnesia_create_tables_if_needed() ->
  mnesia:wait_for_tables([flags], 1000),
  case lists:member(flags, mnesia:system_info(tables)) of
    true -> ok;
    false ->
      mnesia:create_table(flags, [{attributes, record_info(fields, flags)}, {type, bag}]),
      insert_initial_data()
  end.

insert_initial_data() ->
  mnesia:transaction(fun(T) ->
    lists:foreach(fun(X) -> mnesia:write(X) end, T)
                     end, [[
    #flags{name = "^_^", fake = true, value = "Looks like the flag, huh?", algo = "sha1"},
    #flags{name = "_^_^_", fake = true, value = "Try a bit more :)", algo = "sha1"},
    #flags{name = "^^_^^", fake = true, value = "No, this is not the flag :(", algo = "sha256"},
    #flags{name = "^__^", fake = false, value = "I_L0v3_3rl4ng_t00!", algo = "base64"},
    #flags{name = "^^_^", fake = true, value = "Missed a bit", algo = "md5"},
    #flags{name = "^_^^", fake = true, value = "Do you like perl?", algo = "md5"}
  ]]).