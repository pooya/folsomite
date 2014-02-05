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

-module(folsomite_graphite_client_sup).
-behaviour(supervisor).

-export([get_client/0]).
-export([start_link/0]).
-export([init/1]).

-define(APP, folsomite).

%% api
-spec get_client() -> {'error',_} | {'ok',_}.
get_client() ->
    case start_client(get_env(graphite_host), get_env(graphite_port)) of
        {error, {already_started, Pid}} -> {ok, Pid};
        {ok, Pid} -> {ok, Pid};
        {error, Reason} -> {error, Reason}
    end.

%% management api
-spec start_link() -> 'ignore' | {'error',_} | {'ok',pid()}.
start_link() -> supervisor:start_link({local, ?MODULE}, ?MODULE, no_arg).

%% supervisor callback
-spec init('no_arg') -> {'ok',{{'one_for_one',5,10},[]}}.
init(no_arg) -> {ok, {{one_for_one, 5, 10}, []}}.


%% internal
-spec start_client(_,_) -> {'error',_} | {'ok','undefined' | pid()} | {'ok','undefined' | pid(),_}.
start_client(Host, Port) ->
      supervisor:start_child(
        ?MODULE,
        {?APP,
         {folsomite_graphite_client, start_link, [Host, Port]},
         temporary,
         brutal_kill,
         worker,
         [folsomite_graphite_client]}).

-spec get_env('graphite_host' | 'graphite_port') -> any().
get_env(Name) ->
    {ok, Value} = application:get_env(?APP, Name),
    Value.
