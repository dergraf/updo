#!/usr/bin/env escript
%%! -noshell -noinput                                                                                
%% -*- mode: erlang;erlang-indent-level: 4;indent-tabs-mode: nil -*-
%% ex: ft=erlang ts=4 sw=4 et

-define(TIMEOUT, 60000).
-define(INFO(Fmt,Args), io:format(Fmt,Args)).

main([NodeName]) ->
    main([NodeName, undefined]);
main([NodeName, Cookie]) ->
    TargetNode = start_distribution(NodeName, Cookie),
    _UpgradeScript = rpc:call(TargetNode, updo, dry_run, [], ?TIMEOUT),
    ?INFO("code upgrade dry run... ", []),
    {ok, _} = rpc:call(TargetNode, updo, run, [], ?TIMEOUT),
    ?INFO("OK~n", []);
main(_) ->
    ?INFO("script usage:~n", []),
    ?INFO("./upgrade.escript NODENAME [COOKIE]~n", []),
    init:stop(1).

start_distribution(NodeName, Cookie) ->
    MyNode = make_script_node(NodeName),
    {ok, _Pid} = net_kernel:start([MyNode, shortnames]),
    set_cookie(Cookie),
    TargetNode = make_target_node(NodeName),
    case {net_kernel:hidden_connect_node(TargetNode),
          net_adm:ping(TargetNode)} of
        {true, pong} ->
            ok; 
        {_, pang} ->
            io:format("Node ~p not responding to pings.\n", [TargetNode]),
            init:stop(1)
    end,
    TargetNode.

set_cookie(undefined) -> ok;
set_cookie(Cookie) ->
    erlang:set_cookie(node(), list_to_atom(Cookie)).

make_target_node(Node) ->
    [_, Host] = string:tokens(atom_to_list(node()), "@"),
    list_to_atom(lists:concat([Node, "@", Host])).

make_script_node(Node) ->
    list_to_atom(lists:concat([Node, "_upgrader_", os:getpid()])).
