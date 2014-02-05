-module(folsomite_zeta).
-export([event/3, event/4, host_event/3, host_event/4, get_tags/0]).

-define(APP, folsomite).

-spec event(_,_,_) -> any().
event(K, V, Opts) ->
    event(node_prefix(), K, V, [{tags, get_tags()}|Opts]).

-spec event([any()],_,_,_) -> any().
event(Prefix, K, V, Opts) ->
    send_event(Prefix ++ " " ++ K, V, ok, Opts).

-spec host_event(_,_,_) -> any().
host_event(K, V, Opts) ->
    host_event(node_prefix(), K, V, [{tags, get_tags()}|Opts]).

-spec host_event([any()],_,_,_) -> any().
host_event(Prefix, K, V, Opts) ->
    send_event({hostname(), Prefix ++ " " ++ K}, V, ok, Opts).

-spec send_event(nonempty_maybe_improper_list() | {string(),nonempty_maybe_improper_list()},_,'ok',_) -> any().
send_event(_Prefix, _V, _State, _Opts) ->
    ok.

-spec hostname() -> string().
hostname() ->
    net_adm:localhost().

-spec node_prefix() -> nonempty_string().
node_prefix() ->
    NodeList = atom_to_list(node()),
    [A, _] = string:tokens(NodeList, "@"),
    A.

-spec get_tags() -> any().
get_tags() ->
    case application:get_env(?APP, tags) of
        {ok, Value} ->
            Value;
        undefined ->
            []
    end.

