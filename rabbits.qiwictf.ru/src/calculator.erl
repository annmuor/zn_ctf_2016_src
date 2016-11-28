%%%-------------------------------------------------------------------
%%% @author kreon
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Окт. 2016 1:58
%%%-------------------------------------------------------------------
-module(calculator).
-author("kreon").

-behaviour(gen_server).

%% API
-export([start_link/0]).
%% API
-export([calculate/1, calculate_clear/1, get_prev_cmd/0, get_result/0]).
%% gen_server callbacks
-export([init/1,
  handle_call/3,
  handle_cast/2,
  handle_info/2,
  terminate/2,
  code_change/3]).

-define(SERVER, ?MODULE).

-record(state, {
  prev_cmd = "" :: string(),
  result = "" :: term()
}).

%%%===================================================================
%%% API
%%%===================================================================

start_link() ->
  gen_server:start_link({local, ?SERVER}, ?MODULE, [], []).

calculate_clear(Command) ->
  gen_server:call(?MODULE, {calculate_clear, Command}).

calculate(Command) ->
  gen_server:call(?MODULE, {calculate, Command}).

get_prev_cmd() ->
  gen_server:call(?MODULE, {get_prev_cmd}).

get_result() ->
  gen_server:call(?MODULE, {get_result}).

%%%===================================================================
%%% gen_server callbacks
%%%===================================================================

init([]) ->
  {ok, #state{prev_cmd = " ", result = " "}}.

handle_call({calculate_clear, Command}, _From, State) ->
  Command0 = clear_string(Command),
  handle_call({calculate, Command0}, _From, State);

handle_call({calculate, Command}, _From, State) ->
  case eval(Command) of
    {ok, Result} ->
      {reply, ok, State#state{result = Result, prev_cmd = Command}};
    {error, E} ->
      rabbit:log(debug, "Eval() error: ~p", [E]),
      {reply, error, State#state{prev_cmd = Command}}
  end;

handle_call({get_result}, _From, State) ->
  {reply, {ok, clear_string(lists:flatten(io_lib:format("~p", [State#state.result])))}, State};

handle_call({get_prev_cmd}, _From, State) ->
  {reply, {ok, State#state.prev_cmd}, State};

handle_call(_Request, _From, State) ->
  {reply, {error, nosuchcmd}, State}.


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

eval(Command) ->
  Command0 = "Result = " ++ Command ++ ".",
  try
    {ok, String, _} = erl_scan:string(Command0),
    {ok, Evl} = erl_parse:parse_exprs(String),
    {value, X, Bindings} = erl_eval:exprs(Evl, []),
    case lists:keyfind('Result', 1, Bindings) of
      false ->
        {error, noresult};
      {'Result', X} ->
        {ok, X}
    end
  catch _E:_Ee ->
    {error, {_E, _Ee}}
  end.

clear_string(S) ->
  clear_string(S, []).

clear_string([], R) ->
  R;
clear_string([C | S], R) when (((C >= $0) and (C =< $9)) or ((C == $+) or (C == $-) or (C == $*) or (C == $/))) ->
  clear_string(S, R ++ [C]);

clear_string([_ | S], R) ->
  clear_string(S, R).
