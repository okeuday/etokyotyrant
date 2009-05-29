%%%-------------------------------------------------------------------
%%% File    : medici_conn.erl
%%% Author  : Jim McCoy <>
%%% Description : principe connection handler and server
%%%
%%% Created :  1 May 2009 by Jim McCoy <>
%%%-------------------------------------------------------------------
-module(medici_native_conn).

-behaviour(gen_server).

%% API
-export([start_link/0]).

%% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
	 terminate/2, code_change/3]).

-define(DEFAULT_CONTROLLER, medici).
-ifdef(DEBUG).
-define(DEBUG_LOG(Msg, Args), error_logger:error_msg(Msg, Args)).
-else.
-define(DEBUG_LOG(_Msg, _Args), void).
-endif.

-record(state, {socket, mod, endian, controller}).

%%====================================================================
%% API
%%====================================================================
%%--------------------------------------------------------------------
%% Function: start_link() -> {ok,Pid} | ignore | {error,Error}
%% Description: Starts the server
%%--------------------------------------------------------------------
start_link() ->
    {ok, MediciOpts} = application:get_env(options),
    gen_server:start_link(?MODULE, MediciOpts, []).

%%====================================================================
%% gen_server callbacks
%%====================================================================

%%--------------------------------------------------------------------
%% Function: init(Args) -> {ok, State} |
%%                         {ok, State, Timeout} |
%%                         ignore               |
%%                         {stop, Reason}
%% Description: Initiates the server
%%--------------------------------------------------------------------
init(ClientProps) ->
    {ok, Sock} = principe:connect(ClientProps),
    case get_db_type(Sock) of
	{ok, _Endian, table} ->
	    {error, bad_tyrant_mode_for_native_storage};
	{ok, _Endian, fixed} ->
	    {error, bad_tyrant_mode_for_native_storage};
	{ok, Endian, _} ->
	    Controller = proplists:get_value(controller, ClientProps, ?DEFAULT_CONTROLLER),
	    Controller ! {client_start, self()},
	    process_flag(trap_exit, true),
	    {ok, #state{socket=Sock, mod=principe, endian=Endian, controller=Controller}};
	{error, _} ->
	    {stop, connect_failure}
    end.

%%--------------------------------------------------------------------
%% Function: %% handle_call(Request, From, State) -> {reply, Reply, State} |
%%                                      {reply, Reply, State, Timeout} |
%%                                      {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, Reply, State} |
%%                                      {stop, Reason, State}
%% Description: Handling call messages
%%--------------------------------------------------------------------
handle_call(Request, _From, State) ->
    ?DEBUG_LOG("Unknown call ~p~n", [Request]),
    {stop, {unknown_call, Request}, State}.

%%--------------------------------------------------------------------
%% Function: handle_cast(Msg, State) -> {noreply, State} |
%%                                      {noreply, State, Timeout} |
%%                                      {stop, Reason, State}
%% Description: Handling cast messages
%%--------------------------------------------------------------------

%% This section differs from the regular medici_conn module in that calls
%% which return data are given their own functions so that the data can
%% be converted back to erlang terms prior to being sent to the requestor.

handle_cast(stop, State) ->
    {stop, asked_to_stop, State};
handle_cast({From, iternext}=Request, State) ->
    Module = State#state.mod,
    Result = Module:iternext(State#state.socket),
    case Result of
	{error, conn_closed} ->
	    State#state.controller ! {retry, self(), Result, Request},
	    {stop, connection_error, State};
	{error, conn_error} ->
	    State#state.controller ! {retry, self(), Result, Request},
	    {stop, connection_error, State};
	{error, Reason} ->
	    gen_server:reply(From, {error, Reason}),
	    {noreply, State};
	_ ->
	    gen_server:reply(From, binary_to_term(Result)),
	    {noreply, State}
    end;
handle_cast({From, get, Key}=Request, State) ->
    Module = State#state.mod,
    Result = Module:get(State#state.socket, Key),
    case Result of
	{error, conn_closed} ->
	    State#state.controller ! {retry, self(), Result, Request},
	    {stop, connection_error, State};
	{error, conn_error} ->
	    State#state.controller ! {retry, self(), Result, Request},
	    {stop, connection_error, State};
	_ ->
	    gen_server:reply(From, binary_to_term(Result)),
	    {noreply, State}
    end;
handle_cast({From, mget, KeyList}=Request, State) ->
    Module = State#state.mod,
    Result = Module:mget(State#state.socket, KeyList),
    case Result of
	{error, conn_closed} ->
	    State#state.controller ! {retry, self(), Result, Request},
	    {stop, connection_error, State};
	{error, conn_error} ->
	    State#state.controller ! {retry, self(), Result, Request},
	    {stop, connection_error, State};
	_ ->
	    ResultList = [{binary_to_term(K), binary_to_term(V)} || {K, V} <- Result],
	    gen_server:reply(From, ResultList),
	    {noreply, State}
    end;
handle_cast({From, CallFunc}=Request, State) when is_atom(CallFunc) ->
    Module = State#state.mod,
    Result = Module:CallFunc(State#state.socket),
    case Result of
	{error, conn_closed} ->
	    State#state.controller ! {retry, self(), Result, Request},
	    {stop, connection_error, State};
	{error, conn_error} ->
	    State#state.controller ! {retry, self(), Result, Request},
	    {stop, connection_error, State};
	_ ->
	    gen_server:reply(From, Result),
	    {noreply, State}
    end;
handle_cast({From, CallFunc, Arg1}=Request, State) when is_atom(CallFunc) ->
    Module = State#state.mod,
    Result = Module:CallFunc(State#state.socket, Arg1),
    case Result of
	{error, conn_closed} ->
	    State#state.controller ! {retry, self(), Result, Request},
	    {stop, connection_error, State};
	{error, conn_error} ->
	    State#state.controller ! {retry, self(), Result, Request},
	    {stop, connection_error, State};
	_ ->
	    gen_server:reply(From, Result),
	    {noreply, State}
    end;
handle_cast({From, CallFunc, Arg1, Arg2}=Request, State) when is_atom(CallFunc) ->
    Module = State#state.mod,
    Result = Module:CallFunc(State#state.socket, Arg1, Arg2),
    case Result of
	{error, conn_closed} ->
	    State#state.controller ! {retry, self(), Result, Request},
	    {stop, connection_error, State};
	{error, conn_error} ->
	    State#state.controller ! {retry, self(), Result, Request},
	    {stop, connection_error, State};
	_ ->
	    gen_server:reply(From, Result),
	    {noreply, State}
    end.


%%--------------------------------------------------------------------
%% Function: handle_info(Info, State) -> {noreply, State} |
%%                                       {noreply, State, Timeout} |
%%                                       {stop, Reason, State}
%% Description: Handling all non call/cast messages
%%--------------------------------------------------------------------
handle_info(_Info, State) ->
    ?DEBUG_LOG("An unknown info message was received: ~w~n", [_Info]),
    %%% XXX: does this handle tcp connection closed events?
    {noreply, State}.

%%--------------------------------------------------------------------
%% Function: terminate(Reason, State) -> void()
%% Description: This function is called by a gen_server when it is about to
%% terminate. It should be the opposite of Module:init/1 and do any necessary
%% cleaning up. When it returns, the gen_server terminates with Reason.
%% The return value is ignored.
%%--------------------------------------------------------------------
terminate(_Reason, State) ->
    Module = State#state.mod,
    Module:sync(State#state.socket),
    gen_tcp:close(State#state.socket),
    State#state.controller ! {client_end, self()},
    ok.

%%--------------------------------------------------------------------
%% Func: code_change(OldVsn, State, Extra) -> {ok, NewState}
%% Description: Convert process state when code is changed
%%--------------------------------------------------------------------
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%%--------------------------------------------------------------------
%%% Internal functions
%%--------------------------------------------------------------------

%% Query the remote end of the socket to get the remote database type
get_db_type(Socket) when is_port(Socket) ->
    StatInfo = principe:stat(Socket),
    case StatInfo of
	{error, Reason} ->
	    {error, Reason};
	StatList ->
	    case proplists:get_value(bigend, StatList) of
		"0" ->
		    Endian = little;
		_ ->
		    Endian = big
	    end,
	    case proplists:get_value(type, StatList) of
		"on-memory hash" -> 
		    Type = hash;
		"table" -> 
		    Type = table;
		"on-memory tree" -> 
		    Type = tree;
		"B+ tree" -> 
		    Type = tree;
		"hash" ->
		    Type = hash;
		"fixed-length" ->
		    Type = fixed;
		_ -> 
		    ?DEBUG_LOG("~p:get_db_type returned ~p~n", [?MODULE, proplists:get_value(type, StatList)]),
		    Type = error
	    end,
	    case Type of
		error ->
		    {error, unknown_db_type};
		_ ->
		    {ok, Endian, Type}
	    end	    
    end.