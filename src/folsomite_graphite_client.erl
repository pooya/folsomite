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

-module(folsomite_graphite_client).
-behaviour(gen_server).

-export([start_link/2]).
-export([send/2]).
-export([init/1, terminate/2, handle_call/3, handle_cast/2,
         handle_info/2, code_change/3]).

-record(state, {tcp_socket :: inet:socket()}).

%% management api
-spec start_link(_,_) -> 'ignore' | {'error',_} | {'ok',pid()}.
start_link(Host, Port) -> gen_server:start_link(?MODULE, [Host, Port], []).

%% api
-spec send(atom() | pid() | {atom(),_} | {'via',_,_},_) -> 'ok'.
send(Socket, Message) -> gen_server:cast(Socket, {send, Message}).

%% gen_server callbacks
-spec init([atom() | string() | char() | {byte(),byte(),byte(),byte()} | {char(),char(),char(),char(),char(),char(),char(),char()},...]) -> {'ok',#state{tcp_socket::port()}} | {'stop',atom()}.
init([Host, Port]) ->
    SocketOpts = [binary, {active, false}],
    case gen_tcp:connect(Host, Port, SocketOpts, 5000) of
        {ok, TCPSocket} ->
            {ok, #state{tcp_socket = TCPSocket}};
        {error, Reason} ->
            error_logger:error_msg("Connection to ~p:~p failed with reason ~p.",
                                   [Host, Port, Reason]),
            {stop, Reason}
    end.

-spec handle_call(_,_,_) -> {'noreply',_}.
handle_call(Call, _, State) ->
    unexpected(call, Call),
    {noreply, State}.

-spec handle_cast(_,_) -> {'noreply',_} | {'stop',{'shutdown','connection_closed'},#state{tcp_socket::port()}}.
handle_cast({send, Message}, #state{tcp_socket = TCPSocket} = State) ->
    case gen_tcp:send(TCPSocket, Message) of
        ok ->
            {noreply, State};
        {error, closed} ->
            error_logger:info_msg("folsomite_graphite_client disconnected"),
            {stop, {shutdown, connection_closed}, State}
    end;
handle_cast(Cast, State) ->
    unexpected(cast, Cast),
    {noreply, State}.

-spec handle_info(_,_) -> {'noreply',_}.
handle_info(Info, State) ->
    unexpected(info, Info),
    {noreply, State}.

-spec terminate(_,#state{tcp_socket::'undefined' | port()}) -> 'ok'.
terminate(_, #state{tcp_socket = TCPSocket}) ->
    case TCPSocket of
        undefined -> ok;
        TCPSocket1 -> gen_tcp:close(TCPSocket1)
    end.

-spec code_change(_,_,_) -> {'ok',_}.
code_change(_, State, _) -> {ok, State}.


%% internal
-spec unexpected('call' | 'cast' | 'info',_) -> 'ok'.
unexpected(Type, Message) ->
    error_logger:info_msg(" unexpected ~p ~p~n", [Type, Message]).
