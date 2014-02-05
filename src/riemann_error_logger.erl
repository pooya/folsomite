%% Copyright (c) 2012 Campanja AB
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% A copy of the license is included in the file LICENSE.
%%
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

%% @doc gen_event module that is an error_logger
%% that takes crash reports from error_logger/sasl
%% and forwards them to riemann.

-module(riemann_error_logger).
-behaviour(gen_event).

%% gen_event callbacks
-export([init/1, handle_event/2, handle_call/2,
         handle_info/2, terminate/2, code_change/3]).

%% API
-export([register_with_logger/0]).

-record(state, {node_prefix :: string()}).


-spec register_with_logger() -> any().
register_with_logger() ->
    error_logger:add_report_handler(?MODULE).

-spec init(_) -> {'ok',#state{node_prefix::nonempty_string()}}.
init(_) ->
    State = #state{node_prefix = node_prefix()},
    {ok, State}.

-spec handle_call(_,_) -> {'ok','not_ok',_}.
handle_call(_Request, State) ->
    {ok, not_ok, State}.

-spec handle_event(_,_) -> {'ok',_}.
handle_event({error, _GL, {_Pid, Fmt, Data}}, State) ->
    case Fmt of
        "** Generic server "++_ ->
            Info = lists:flatten(io_lib:format(Fmt, Data)),
            send_stats(State, Info);
        "** State machine "++_ ->
            Info = lists:flatten(io_lib:format(Fmt, Data)),
            send_stats(State, Info);
        "** gen_event handler"++_ ->
            Info = lists:flatten(io_lib:format(Fmt, Data)),
            send_stats(State, Info);
        _ ->
            ok
    end,
    {ok, State};
handle_event({error_report, _G, {_Pid, crash_report, [Self, _Neigb]}}, State) ->
    Info = lists:flatten(io_lib:format("error report:~p~n",[Self])),
    send_stats(State, Info),
    {ok, State};
handle_event(_Event, State) ->
    {ok, State}.


-spec handle_info(_,_) -> {'ok',_}.
handle_info(_Info, State) ->
    {ok, State}.

-spec terminate(_,_) -> 'ok'.
terminate(_Reason, _State) ->
    ok.

-spec code_change(_,_,_) -> {'ok',_}.
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.


%% Internal functions
-spec node_prefix() -> nonempty_string().
node_prefix() ->
    NodeList = atom_to_list(node()),
    [A, _] = string:tokens(NodeList, "@"),
    A.

-spec send_stats(#state{node_prefix::string()},string()) -> any().
send_stats(_State, _Data)->
    ok.

