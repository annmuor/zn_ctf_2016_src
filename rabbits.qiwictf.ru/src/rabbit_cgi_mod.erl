%%%-------------------------------------------------------------------
%%% @author kreon
%%% @copyright (C) 2016, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Окт. 2016 1:57
%%%-------------------------------------------------------------------
-module(rabbit_cgi_mod).
-author("kreon").
-include("/usr/lib/yaws/include/yaws_api.hrl").
-include("../include/guestbook.hrl").
%% API
-export([out/1]).
out(Arg) ->
  case rabbit:check_for_random(Arg) of
    ok -> out1(Arg);
    X -> X
  end.

out1(Arg) ->
  if
    Arg#arg.pathinfo == "/calculator.pl" -> calculator_pl(Arg);
    Arg#arg.pathinfo == "/guestbook.pl" -> guestbook_pl(Arg);
    Arg#arg.pathinfo == "/filemanager.pl" -> filemanager_pl(Arg);
    Arg#arg.pathinfo == "/gallery.pl" -> gallery_pl(Arg);
    true ->
      [{status, 404}, {content, "text/html", "404 NOT FOUND"}]
  end.
%%% CALCULATOR LOL %%%
calculator_pl(Arg) when Arg#arg.req#http_request.method == 'POST' ->
  Post = yaws_api:parse_post(Arg),
  case lists:keyfind("s", 1, Post) of
    false -> {redirect_local, "/cgi-bin/calculator.pl"};
    _ ->
      Cmd = lists:flatmap(fun({"cmd[]", X}) -> X;(_) -> "" end, Post),
      calculator:calculate_clear(Cmd),
      {redirect_local, "/cgi-bin/calculator.pl"}
  end;
calculator_pl(_) ->
  {ok, Result} = calculator:get_result(),
  {ok, Cmd} = calculator:get_prev_cmd(),
  {ssi, "calculator.yaws", "%%", [{"cmd", Cmd}, {"result", Result}]}.

guestbook_pl(Arg) when Arg#arg.req#http_request.method == 'POST' ->
  Post = yaws_api:parse_post(Arg),
  %% check capctha
  case lists:keyfind("captcha", 1, Post) of
    false ->
      {redirect_local, "/cgi-bin/guestbook.pl?error=captcha"};
    {_, Captcha} ->
      Formula = case yaws_api:find_cookie_val("_check", Arg#arg.headers#headers.cookie) of
                  [] -> gen_rand_formula();
                  V1 -> V1
                end,
      calculator:calculate(Formula),
      {ok, Captcha1} = calculator:get_result(),
      if
        Captcha1 =:= Captcha -> post_to_guestbook(Post, Arg#arg.client_ip_port);
        true ->
          rabbit:log(debug, "Captcha ~p != ~p for ~p", [Captcha, Captcha1, Formula]),
          {redirect_local, "/cgi-bin/guestbook.pl?error=captcha"}
      end
  end;

guestbook_pl(Arg) ->
  Start = case yaws_api:queryvar(Arg, "s") of
            {ok, _Val} -> list_to_integer(_Val);
            undefined -> 0
          end,
  Count = case yaws_api:queryvar(Arg, "c") of
            {ok, Val} -> list_to_integer(Val);
            undefined -> 30
          end,
  E1 = case yaws_api:queryvar(Arg, "error") of
         {ok, Val1} -> Val1;
         undefined -> []
       end,
  Error = if length(E1) =:= 0 -> []; true -> "Please fix error: " ++ E1 end,
  Next = integer_to_list(Start + 30),
  Prev = integer_to_list(if
                           Start < 30 -> 0;
                           true ->
                             Start - 30
                         end),
  Formula = gen_rand_formula(),
  [{ssi, "guestbook.yaws", "%%", [
    {"messages", guestbook2ehtml(Start, Count)},
    {"next", Next},
    {"prev", Prev},
    {"formula", Formula},
    {"error", Error}
  ]}, yaws_api:set_cookie("_check", Formula, [])].

filemanager_pl(_Arg) ->
  {status, 500}.

gallery_pl(_Arg) ->
  {status, 500}.

%% internal

htmlspecialchars(T) ->
  htmlspecialchars(binary_to_list(T), []).

htmlspecialchars([], R) -> list_to_binary(R);
htmlspecialchars([$< | T], R) ->
  htmlspecialchars(T, R ++ "&lt;");
htmlspecialchars([$> | T], R) ->
  htmlspecialchars(T, R ++ "&gt;");
htmlspecialchars([$" | T], R) ->
  htmlspecialchars(T, R ++ "&quot;");
htmlspecialchars([H | T], R) ->
  htmlspecialchars(T, R ++ [H]).

guestbook2ehtml(M, N) ->
  {posts, Data} = guestbook:read(M, N),
  {ehtml, lists:map(fun(X) ->
    Email = htmlspecialchars(X#guestbook.email),
    Name = htmlspecialchars(X#guestbook.name),
    Msg = htmlspecialchars(X#guestbook.message),
    {tr, [{style, "min-height:300px"}], [
      {th, [{align, "left"}, {valign, "top"}], {ul, [], [
        {li, [], Name},
        {li, [], {a, [{href, "mailto:" ++ Email}], Email}},
        {li, [{style, "color:#ffa07a"}], X#guestbook.ip_address}
      ]
      }},
      {td, [{align, "left"}, {valign, "top"}], Msg}]
    }
                    end, Data)}.

gen_rand_formula() ->
  Op1 = rand:uniform(100),
  Op2 = rand:uniform(100),
  Op = case rand:uniform(3) of
         1 -> "+";
         2 -> "-";
         3 -> "*"
       end,
  integer_to_list(Op1) ++ Op ++ integer_to_list(Op2).

post_to_guestbook(Post, {IP, _Port}) ->
  Name = case lists:keyfind("name", 1, Post) of
           {_, V} -> V;
           false -> undefined
         end,
  Email = case lists:keyfind("email", 1, Post) of
            {_, V1} -> V1;
            false -> undefined
          end,
  Message = case lists:keyfind("message", 1, Post) of
              {_, V2} -> V2;
              false -> undefined
            end,
  IP1 = inet:ntoa(IP),
  if
    (is_atom(Name) or is_atom(Email) or is_atom(Message)) ->
      {redirect_local, "/cgi-bin/guestbook.pl?error=post"};
    true ->
      guestbook:post(#guestbook{
        name = list_to_binary(Name),
        email = list_to_binary(Email),
        message = list_to_binary(Message),
        ip_address = list_to_binary(IP1)
      }),
      {redirect_local, "/cgi-bin/guestbook.pl"}
  end.

