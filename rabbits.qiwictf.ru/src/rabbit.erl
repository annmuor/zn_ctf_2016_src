%%%-------------------------------------------------------------------
%%% @author kreon
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Окт. 2016 1:04
%%%-------------------------------------------------------------------
-module(rabbit).
-author("kreon").
-include("/usr/lib/yaws/include/yaws_api.hrl").
%% API
-export([start/0, log/3, arg_rewrite/1, check_for_random/1, get_eetaifeci0Eele0chaiwae3coo6ik0Ke_flag/0]).

log(debug, FormatStr, Args) ->
  gen_event:notify(error_logger, {debug_msg, group_leader(), {self(), FormatStr, Args}});
log(info, FormatStr, Args) ->
  error_logger:info_msg(FormatStr, Args);
log(warning, FormatStr, Args) ->
  error_logger:warning_msg(FormatStr, Args);
log(error, FormatStr, Args) ->
  error_logger:error_msg(FormatStr, Args);
log(Level, FormatStr, Args) ->
  error_logger:error_msg("Unknown logging level ~p  ," ++ FormatStr, [Level | Args]).

start() ->
  case wait_for_yaws() of
    ok ->
      log(info, "Starting rabbit~n", []),
      application:start(rabbit);
    Error ->
      log(error, "Failed waiting for Yaws to start when starting Yapp: ~p~n", [Error])
  end.

%% API
arg_rewrite(Arg) ->
  arg_rewrite0(Arg).


%% return 200 ok for any .xxx file :)
check_for_random(Arg) ->
  {abs_path, Path} = Arg#arg.req#http_request.path,
  case lists:reverse(string:tokens(Path, "/")) of
    [] -> check_for_random0(Path);
    [[$. | _] | _] -> generate_random_data();
    _ -> check_for_random0(Path)
  end.

check_for_random0(Path) ->
  case lists:suffix(".yaws", Path) of
    false -> ok;
    true -> generate_random_data()
  end.

get_eetaifeci0Eele0chaiwae3coo6ik0Ke_flag() ->
  'Nice! The flag is: sha1(OTP rulez!)'.

% @hidden
generate_random_data() ->
  Size = rand:uniform(1024 * 1024 * 1024),
  Self = self(),
  spawn_link(fun() ->
    process_flag(trap_exit, true),
    Port = open_port({spawn, "dd if=/dev/urandom bs=1024 count=" ++ integer_to_list(Size) ++ " 2>/dev/null"}, [binary, stream, eof]),
    rec_loop(Self, Port) end),
  {streamcontent, "application/octet-stream", <<>>}.

arg_rewrite0(Arg) ->
  case Arg#arg.headers#headers.x_forwarded_for of
    undefined ->
      Arg;
    Value ->
      {_, Port} = Arg#arg.client_ip_port,
      case inet:ip(Value) of
        {error, Err} ->
          Arg#arg{state = #rewrite_response{status = 403, content = list_to_binary(io_lib:format("Error while parsing ~p: ~p", [Arg#arg.client_ip_port, Err]))}};
        {ok, IP} ->
          Arg#arg{client_ip_port = {IP, Port}}
      end
  end.

rec_loop(Pid, Port) ->
  receive
    {Port, {data, D}} ->
      yaws_api:stream_chunk_deliver(Pid, D),
      %% in very rare case add some strings flag to data
      yaws_api:stream_chunk_deliver(Pid, get_random_words()),
      rec_loop(Pid, Port);
    {Port, eof} ->
      port_close(Port),
      yaws_api:stream_chunk_end(Pid),
      exit(normal);
    {'EXIT', Pid, _} ->
      log(info, "Parent exiting, closing the port NOW", []),
      port_close(Port),
      exit(normal)
  end.



wait_for_yaws() ->
  wait_for_yaws(20).

wait_for_yaws(0) ->
  "Error: YAWS startup timeout";
wait_for_yaws(N) ->
  List = application:which_applications(),
  case lists:keysearch(yaws, 1, List) of
    {value, _} -> ok;
    false ->
      receive
      after 1000 ->
        wait_for_yaws(N - 1)
      end
  end.

get_random_words() ->
  case rand:uniform(65535) of
    1337 -> <<"Y0u 4r3 4lm057 d0n3. K33p 7ry1ng!">>;
    31337 -> <<"L33t b0y! W3 kn0w wh0 y0u 4r3!">>;
    666 -> atom_to_binary(get_eetaifeci0Eele0chaiwae3coo6ik0Ke_flag(), utf8);
    443 -> <<"443.v01d t34m l0v3s y0u!">>;
    _ -> <<>>
  end.