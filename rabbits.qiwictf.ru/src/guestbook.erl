%%%-------------------------------------------------------------------
%%% @author kreon
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Окт. 2016 1:58
%%%-------------------------------------------------------------------
-module(guestbook).
-author("kreon").

-behaviour(gen_server).
-include("../include/guestbook.hrl").
%% API
-export([start_link/0]).
%% API
-export([post/1, read/0, read/1, read/2]).
%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {}).

%%%===================================================================
%%% API
%%%===================================================================
post(G) when is_record(G, guestbook) ->
  gen_server:call(?MODULE, {post, G}).

read() ->
  gen_server:call(?MODULE, {read, infinity}).

read(N) ->
  gen_server:call(?MODULE, {read, N}).

read(M, N) ->
  gen_server:call(?MODULE, {read, M, N}).


%%%===================================================================
%%% API
%%%===================================================================


start_link() ->
  mnesia:create_schema([node()]),
  mnesia:start(),
  mnesia_create_tables_if_needed(),
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
  {ok, #state{}}.
handle_call({post, G}, _From, State) ->
  {reply, {status, insert_post(G)}, State};

handle_call({read, infinity}, _From, State) ->
  {reply, {posts, read_posts(infinity)}, State};

handle_call({read, N}, _From, State) ->
  {reply, {posts, read_posts(N)}, State};

handle_call({read, N, M}, _From, State) ->
  {reply, {posts, read_posts(N, M)}, State};

handle_call(_Request, _From, State) ->
  {reply, error, State}.

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
  mnesia:wait_for_tables([guestbook], 1000),
  case lists:member(guestbook, mnesia:system_info(tables)) of
    true -> ok;
    false ->
      mnesia:create_table(guestbook, [{attributes, record_info(fields, guestbook)}, {type, ordered_set}]),
      insert_initial_data()
  end.

insert_initial_data() ->
  lists:foreach(fun(X) -> insert_post(X) end,
    [
      #guestbook{
        name = <<"l33t h4x0r">>,
        email = <<"l33x.h4x0r@ctf.ws">>,
        message = <<"I w1ll h4k u s00n">>,
        ip_address = <<"33.33.33.33">>
      }, #guestbook{
      name = <<"c00l g1rl">>,
      email = <<"c00l.g1rl@ctf.ws">>,
      message = <<"C4ll m3 4t 333-77-11 I s3nd u my h0t p1cs">>,
      ip_address = <<"33.33.33.33">>
    }, #guestbook{
      name = <<"b1g b0ss">>,
      email = <<"b1g.b0ss@ctf.ws">>,
      message = <<"U 4r3 f1r3d! C4ll m3 4t 333-77-11">>,
      ip_address = <<"33.33.33.33">>
    }
    ]).


insert_post(G) when is_record(G, guestbook) ->
  F = fun(X) ->
    mnesia:write(X)
      end,
  case mnesia:transaction(F, [G#guestbook{datetime = erlang:system_time()}]) of
    {atomic, ok} -> ok;
    {aborted, _} -> error
  end.

read_posts(infinity) ->
  case mnesia:transaction(fun() -> Last = mnesia:last(guestbook), read_posts0(Last, [], -1) end) of
    {atomic, R} -> R;
    {aborted, _} -> []
  end;
read_posts(N) when is_integer(N) ->
  case mnesia:transaction(fun() -> Last = mnesia:last(guestbook), read_posts0(Last, [], N) end) of
    {atomic, R} -> R;
    {aborted, _} -> []
  end;
read_posts(_) ->
  read_posts(10).

read_posts(M, N) when ((M >= 0) and (N >= 0)) ->
  case mnesia:transaction(fun() ->
    X = mnesia:last(guestbook),
    X0 = skip_last_keys(X, M),
    read_posts0(X0, [], N)
                          end) of
    {atomic, R} -> R;
    {aborted, _} -> []
  end;
read_posts(_, N) when N >= 0 ->
  read_posts(N);
read_posts(_, _) ->
  read_posts(10).

read_posts0(_, Result, 0) ->
  Result;
read_posts0('$end_of_table', Result, _) ->
  Result;
read_posts0(Id, Result, N) ->
  read_posts0(mnesia:prev(guestbook, Id), Result ++ mnesia:read(guestbook, Id), N - 1).

skip_last_keys('$end_of_table', _) ->
  '$end_of_table';
skip_last_keys(K, 0) ->
  K;
skip_last_keys(K, M) ->
  skip_last_keys(mnesia:prev(guestbook, K), M - 1).
