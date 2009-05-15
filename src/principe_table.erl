%%%-------------------------------------------------------------------
%%% File:      principe.erl
%%% @author    Jim McCoy <mccoy@mad-scientist.com>
%%% @copyright Copyright (c) 2009, Jim McCoy.  All Rights Reserved.
%%%
%%% @doc
%%% An extension to the principe module that handles tables.  See the
%%% principe module docs for a note about Tyrant and server byte-order
%%% issues.  To deal with that particular issue, this module takes as a
%%% parameter a parameterized version of the principe module that has been
%%% set with the proper server endianness (this feels distressingly OO, but
%%% given the inter-module refs I can't see a way around it...)  To get a
%%% properly setup version of this module you would do something like the
%%% following:
%%%
%%%    G = PrincipeMod:new(little).
%%%    T = principe_table:new(G).
%%%
%%% @end
%%%-------------------------------------------------------------------

-module(principe_table,[PrincipeMod]).
-compile([binary_comprehension, export_all]).
%% -export([connect/0, connect/1, put/3, putkeep/3, putcat/3, update/3, out/2,
%% 	 get/2, mget/2, vsiz/2, iterinit/1, iternext/1, fwmkeys/3, sync/1, vanish/1,
%% 	 rnum/1, size/1, stat/1, copy/2, restore/3, addint/3, adddouble/3, adddouble/4,
%% 	 setmst/3, setindex/3, query_set_limit/3, query_set_limit/2,
%% 	 query_add_condition/4, query_set_order/3, search/2, genuid/1,
%% 	 searchcount/2, searchout/2, encode_table/1, decode_table/1]).
%%-export([table/1])  % Not tested yet

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").
-include("test/principe_table_test.erl").
-endif.

-define(NULL, <<0:8>>).

%% Constants for tyrant tables
-define(ITLEXICAL, "0").
-define(ITDECIMAL, "1").
-define(ITOPT, "9998").
-define(ITVOID, "9999").

-define(QCSTREQ, 0).
-define(QCSTRINC, 1).
-define(QCSTRBW, 2).
-define(QCSTREW, 3).
-define(QCSTRAND, 4).
-define(QCSTROR, 5).
-define(QCSTROREQ, 6).
-define(QCSTRRX, 7).
-define(QCNUMEQ, 8).
-define(QCNUMGT, 9).
-define(QCNUMGE, 10).
-define(QCNUMLT, 11).
-define(QCNUMLE, 12).
-define(QCNUMBT, 13).
-define(QCNUMOREQ, 14).
-define(QCNEGATE, 1 bsl 24).
-define(QCNOIDX, 1 bsl 25).

-define(QOSTRASC, 0).
-define(QOSTRDESC, 1).
-define(QONUMASC, 2).
-define(QONUMDESC, 3).

%% Some function patterns that are used frequently
-define(TT(Func, Args), PrincipeMod:misc(Socket, Func, Args)).

%% Some standard types for edoc
%%
%% @type key() = iolist()
%% @type value() = iolist()
%% @type value_or_num() == iolist() | integer() | float()
%% @type keylist() = [key()]
%% @type error() = {error, term()}

%% The Tokyo Tyrant access functions

%% @spec connect() -> {ok, port()} | error()
%%
%% @doc 
%% Establish a connection to the tyrant service.
%% @end
connect() ->
    PrincipeMod:connect().

%% @spec connect(ConnectProps::proplist()) -> {ok, port()} | error()
%%
%% @doc 
%% Establish a connection to the tyrant service using properties in the
%% ConnectProps proplist to determine the hostname, port number and tcp
%% socket options for the connection.  Any missing parameters are filled
%% in using the module defaults.
%% @end
connect(ConnectProps) ->
    PrincipeMod:connect(ConnectProps).

%% table(Socket) ->
%%     TF = fun() -> qlc_next(firstitem(Socket)) end,
%%     InfoFun = fun(num_of_objects) -> PrincipeMod:rnum(Socket);
%%                  (keypos) -> 1;
%%                  (is_sorted_key) -> false;
%%                  (is_unique_objects) -> true;
%%                  (_) -> undefined
%%               end,
%%     LookupFun =
%%         fun(1, Ks) ->
%%                 PrincipeMod:mget(Socket, Ks)
%%         end,
%%     qlc:table(TF, [{info_fun, InfoFun}, {lookup_fun, LookupFun},{key_equality,'=='}]).

%% %% Helper functions for the qlc_next function
%% firstitem(Socket) ->
%%     ok = PrincipeMod:iterinit(Socket),
%%     case PrincipeMod:iternext(Socket) of
%% 	{error, _ErrCode} ->
%% 	    none;
%% 	Key ->
%% 	    {Key, PrincipeMod:get(Socket, Key), Socket}
%%     end.
%% nextitem({_K, _V, Socket}) ->
%%     case PrincipeMod:iternext(Socket) of
%% 	{error, _ErrCode} ->
%% 	    none;
%% 	Key ->
%% 	    {Key, PrincipeMod:get(Socket, Key), Socket}
%%     end.

%% %% The traversal function used by table/1
%% qlc_next({X, V, S}) ->
%%     [{X,V} | fun() -> qlc_next(nextitem({X, V, S})) end];
%% qlc_next(none) ->
%%     [].

%%====================================================================
%%  Standard tyrant functions (straight pass-through to principe.erl)
%%====================================================================

%% @spec addint(Socket::port(),
%%              Key::key(),
%%              Int::integer()) -> integer() | error()
%%
%% @doc Add an integer value to the _num column of a given a key.  The
%% _num column will be created if it does not already exist.
%% @end
addint(Socket, Key, Int) ->
    PrincipeMod:addint(Socket, Key, Int).

%% @spec adddouble(Socket::port(),
%%                 Key::key(),
%%                 Double::float()) -> {Integral::integer(), Fractional::integer()} | error()
%%
%% @doc Add an float value to the _num column of a given a key.  The
%% _num column will be created if it does not already exist.
%% @end
adddouble(Socket, Key, Double) ->
    PrincipeMod:adddouble(Socket, Key, Double).

%% @spec adddouble(Socket::port(),
%%                 Key::key(),
%%                 Integral::integer(),
%%                 Fractional::integer()) -> {Integral::integer(), Fractional::integer()} | error()
%%
%% @doc The raw adddouble function for those who need a bit more control on float adds.
adddouble(Socket, Key, Integral, Fractional) ->
    PrincipeMod:adddouble(Socket, Key, Integral, Fractional).    

%% @spec iterinit(Socket::port()) -> ok | error()
%%
%% @doc Start iteration protocol.  WARNING: The tyrant iteration protocol has no
%% concurrency controls whatsoever, so if multiple clients try to do iteration
%% they will stomp all over each other!
%% @end
iterinit(Socket) ->
    PrincipeMod:iterinit(Socket).

%% @spec iternext(Socket::port()) -> {Key::binary(), Value::binary()} | error()
%%
%% @doc Get the next key/value pair in the iteration protocol.
iternext(Socket) ->
    PrincipeMod:iternext(Socket).

%% @spec fwmkeys(Socket::port(),
%%               Prefix::iolist(),
%%               MaxKeys::integer()) -> [Key()::binary()]
%%
%% @doc Return a number of keys that match a given prefix.
fwmkeys(Socket, Prefix, MaxKeys) ->
    PrincipeMod:fwmkeys(Socket, Prefix, MaxKeys).

%% @spec vsiz(Socket::port(),
%%            Key::key()) -> integer()
%%
%% Get the size of the value for a given key.
vsiz(Socket, Key) ->
    PrincipeMod:vsiz(Socket, Key).

%% @spec sync(Socket::port()) -> ok | error()
%%
%% @doc Call sync() on the remote database.
sync(Socket) ->
    PrincipeMod:sync(Socket).

%% @spec vanish(Socket::port()) -> ok | error()
%%
%% @doc Remove all records from the remote database.
vanish(Socket) ->
    PrincipeMod:vanish(Socket).

%% Get the number of records in the remote database
rnum(Socket) ->
    PrincipeMod:rnum(Socket).

%% @spec size(Socket::port()) -> integer() | error()
%%
%% @doc Get the size in bytes of the remote database.
size(Socket) ->
    PrincipeMod:size(Socket).

%% @spec stat(Socket::port()) -> proplist() | error()
%%
%% @doc Get the status string of a remote database.
stat(Socket) ->
    PrincipeMod:stat(Socket).

%% @spec copy(Socket::port(), 
%%            iolist()) -> ok | error()
%%
%% @doc Make a copy of the database file of the remote database.
copy(Socket, PathName) ->
    PrincipeMod:copy(Socket, PathName).

%% @spec restore(Socket::port(), 
%%               PathName::iolist(), 
%%               TimeStamp::integer) -> ok | error()
%%
%% @doc Restore the database to a particular point in time from the update log.
restore(Socket, PathName, TimeStamp) ->
    PrincipeMod:restore(Socket, PathName, TimeStamp).

%% @spec setmst(Socket::port(), 
%%              HostName::iolist(), 
%%              Port::integer) -> ok | error()
%%
%% @doc Set the replication master of a remote database server.
setmst(Socket, HostName, Port) ->
    PrincipeMod:setmst(Socket, HostName, Port).

%%====================================================================
%%  Table functions
%%====================================================================

%% @spec put(Socket::port(), 
%%           Key::key(), 
%%           Cols::proplist()) -> [] | error()
%%
%% @doc
%% Call the Tyrant server to store a new set of column values for the given key.
%% @end
put(Socket, Key, Cols) ->
    Data = encode_table(Cols),
    ?TT(<<"put">>, [Key | Data]).

%% @spec putkeep(Socket::port(), 
%%               Key::key(), 
%%               Cols::proplist()) -> [] | error()
%%
%% @doc 
%% Call the Tyrant server to add a set of column values for a given key.  Will 
%% return an error if Key is already in the remote database.
%% @end
putkeep(Socket, Key, Cols) ->
    Data = encode_table(Cols),
    ?TT(<<"putkeep">>, [Key | Data]).

%% @spec putcat(Socket::port(), 
%%              Key::key(), 
%%              Cols::proplist()) -> [] | error()
%%
%% @doc 
%% Concatenate a set of column values to the existing value of Key (or
%% create a new entry for Key with the given column values if Key is not
%% in the remote database.)  If any columns in Cols already have values
%% for the given key then the entries provided in the Cols parameter for
%% those specific columns will be ignored by the remote database. Use the
%% update() function to overwrite existing column values.
%% @end
putcat(Socket, Key, Cols) ->
    Data = encode_table(Cols),
    ?TT(<<"putcat">>, [Key | Data]).

%% @spec update(Socket::port(), 
%%              Key::key(), 
%%              Cols::proplist()) -> [] | error()
%%
%% @doc 
%% Update a table entry by merging Cols into existing data for given key. The
%% end result of this function should be to create a new entry for Key whose
%% column values are the new data from the Cols parameter as well as any previous
%% columns for Key that were not in the Cols proplist.
%% @end
%%
%% TODO: better way would be to use a lua server script to perform the merge?
update(Socket, Key, Cols) ->
    case PrincipeMod:misc(Socket, <<"get">>, [Key]) of
	{error, _Reason} ->
	    NewData = Cols;
	ExistingData ->
	    OldProps = decode_table(ExistingData),
	    NewProps = lists:foldl(fun({K, V}, AccIn) when is_list(K) ->
					   [{list_to_binary(K), V} | AccIn];
				      ({K, V}, AccIn) when is_atom(K) ->
					   [{list_to_binary(atom_to_list(K)), V} | AccIn];
				      (Other, AccIn) -> [Other | AccIn]
				   end, OldProps, Cols),
	    UpdatedProps = [{K, proplists:get_value(K, NewProps)} || K <- proplists:get_keys(NewProps)],
    end,
    Data = encode_table(UpdatedProps),
    ?TT(<<"put">>, [Key | Data]).

%% @spec out(Socket::port(), 
%%           Key::key()) -> ok | error()
%%
%% @doc 
%% Remove a key from the remote database.  Will return an error if Key is
%% not in the database.
%% @end
out(Socket, Key) ->
    ?TT(<<"out">>, [Key]).

%% @spec get(Socket::port(), 
%%           Key::key()) -> proplist() | error()
%%
%% @doc Get the value for a given key. Table data is returned in a proplist of
%% {ColumnName, ColumnValue} tuples.
%% @end
get(Socket, Key) ->
    ?TT(<<"get">>, [Key]).

%% @spec mget(Socket::port(),
%%            KeyList::keylist()) -> [{Key::binary(), Value::proplist()}] | error()
%%
%% @doc Get the values for a list of keys.
mget(Socket, KeyList) ->
    ?TT(<<"getlist">>, [KeyList]).

%% @spec setindex(Socket::port(),
%%                primary | ColName::iolist(),
%%                lexical | decimal | void) -> [] | error()
%%
%% @doc
%% Tell the tyrant server to build an index for a column.  The ColName
%% should be either the atom "primary" (to index on the primary key) or a 
%% iolist() that names the column to be indexed. Type should be an atom
%% selected from decimal (index column as decimal data), lexical (index as
%% character/string data) or void (remove an existing index for ColName).
%% @end
setindex(Socket, primary, Type) when is_atom(Type) ->
    ?TT(<<"setindex">>, [?NULL, setindex_request_val(Type)]);
setindex(Socket, ColName, Type) when is_atom(Type) ->
    ?TT(<<"setindex">>, [ColName, setindex_request_val(Type)]).

%% @spec genuid(Socket::port()) -> [] | error()
%%
%% @doc Generate a unique id within the set of primary keys
genuid(Socket) ->
    ?TT(<<"genuid">>, []).

%% Add a condition for a query.  ExprList should be a list of one or more
%% values where each value is either a binary, list, or integer.  Op can be
%% either an atom or a tuple of atoms describing the operation.  If the first
%% atom in an Op tuple is "no" then the condition is a negation query and if
%% the last atom is no_index an existing index on the remote database server will
%% be bypassed.
query_add_condition(Query, ColName, Op, ExprList) when is_list(ExprList) ->
    [{add_cond, {ColName, <<(add_condition_op_val(Op)):32>>, convert_query_exprlist(ExprList)}} | Query].

%% Set a limit on the number of returned values
query_set_limit(Query, Max, Skip) when is_integer(Max), is_integer(Skip) ->
    case proplists:is_defined(set_limit, Query) of
	true ->
	    ClearedQuery = proplists:delete(set_limit, Query),
	    [{set_limit, {integer_to_list(Max), integer_to_list(Skip)}} | ClearedQuery];
	false ->
	    [{set_limit, {integer_to_list(Max), integer_to_list(Skip)}} | Query]
    end.
%%% XXX: should the missing skip be 0 or -1 (protocol ref and perl versions seem to disagree)
query_set_limit(Query, Max) ->
    query_set_limit(Query, Max, 0).

%% Set the order for returned values
query_set_order(Query, primary, Type) when is_atom(Type) ->
    case proplists:is_defined(set_order, Query) of
	true ->
	    ClearedQuery = proplists:delete(set_order, Query),
	    [{set_order, {?NULL, order_request_val(Type)}} | ClearedQuery];
	false ->
	    [{set_order, {?NULL, order_request_val(Type)}} | Query]
    end;
query_set_order(Query, ColName, Type) when is_atom(Type) ->
    case proplists:is_defined(set_order, Query) of
	true ->
	    ClearedQuery = proplists:delete(set_order, Query),
	    [{set_order, {ColName, order_request_val(Type)}} | ClearedQuery];
	false ->
	    [{set_order, {ColName, order_request_val(Type)}} | Query]
    end.

%% Run a prepared query against the table and return matching keys.
search(Socket, TblQuery) ->
    SearchQuery = query_to_argslist(TblQuery),
    ?TT(<<"search">>, SearchQuery).

%% Run a prepared query against the table and get the count of matching keys.
searchcount(Socket, TblQuery) ->
    SearchQuery = query_to_argslist(TblQuery),
    CountQuery = [SearchQuery | <<"count">>],
    ?TT(<<"search">>, CountQuery).

%% %% Run a prepared query against the table and get the matching records.  Due
%% %% to protocol restraints, the returned result cannot include columns whose
%% %% name or value include the null (0x0) character.
%% tblsearchget(Socket, TblQuery) ->
%%     void.

%% no_nulls(Binary) when is_binary(Binary) ->
%%     no_nulls(binary_to_list(Binary));
%% no_nulls(List) when is_list(List) ->
%%     not(lists:member(0, List)).

%% Run a prepared query against the table and remove the matching records
searchout(Socket, TblQuery) ->
    SearchQuery = query_to_argslist(TblQuery),
    OutQuery = [SearchQuery | <<"out">>],
    ?TT(<<"search">>, OutQuery).

%% tblrescols(Socket, TblQuery) ->
%%     void.

 
%%====================================================================
%%  Table utility functions
%%====================================================================

add_condition_op_val({no, Op}) when is_atom(Op) ->
    ?QCNEGATE bor add_condition_op_val(Op);
add_condition_op_val({Op, no_index}) when is_atom(Op) ->
    ?QCNOIDX bor add_condition_op_val(Op);
add_condition_op_val({no, Op, no_index}) when is_atom(Op)->
    ?QCNEGATE bor ?QCNOIDX bor add_condition_op_val(Op);
add_condition_op_val(Op) when is_atom(Op) ->
    case Op of
	str_eq ->
	    ?QCSTREQ;
	str_inc ->
	    ?QCSTRINC;
	str_begin ->
	    ?QCSTRBW;
	str_end ->
	    ?QCSTREW;
	str_and ->
	    ?QCSTRAND;
	str_or ->
	    ?QCSTROR;
	str_regex ->
	    ?QCSTRRX;
	num_eq ->
	    ?QCNUMEQ;
	num_gt ->
	    ?QCNUMGT;
	num_ge ->
	    ?QCNUMGE;
	num_lt ->
	    ?QCNUMLT;
	num_le ->
	    ?QCNUMLE;
	num_between ->
	    ?QCNUMBT;
	num_in_list ->
	    ?QCNUMOREQ
    end.

setindex_request_val(Type) ->
    case Type of
	lexical ->
	    ?ITLEXICAL;
	decimal ->
	    ?ITDECIMAL;
	optimized ->
	    ?ITOPT;
	void ->
	    ?ITVOID
    end.

order_request_val(Type) ->
    case Type of
	str_ascending ->
	    ?QOSTRASC;
	str_descending ->
	    ?QOSTRDESC;
	num_ascending ->
	    ?QONUMASC;
	num_descending ->
	    ?QONUMDESC
    end.

convert_query_exprlist(ExprList) ->
    convert_query_exprlist(ExprList, []).

convert_query_exprlist([H | T], []) when is_integer(H) ->
    convert_query_exprlist(T, [integer_to_list(H)]);
convert_query_exprlist([H | T], []) ->
    convert_query_exprlist(T, [H]);
convert_query_exprlist([H | T], Acc) when is_integer(H) ->
    convert_query_exprlist(T, [integer_to_list(H) | ["," | Acc]]);
convert_query_exprlist([H | T], Acc) ->
    convert_query_exprlist(T, [H | ["," | Acc]]);
convert_query_exprlist([], Acc) ->
    lists:reverse(Acc).

query_to_argslist(QueryProplist) ->
    query_to_argslist(QueryProplist, []).

query_to_argslist([{K, V} | T], BinArgs) ->
    case K of
	add_cond ->
	    {ColName, Op, ExprList} = V,
	    query_to_argslist(T, [["addcond", ?NULL, ColName, ?NULL, Op, ?NULL, ExprList] | BinArgs]);
	set_limit ->
	    {M, S} = V,
	    query_to_argslist(T, [["setlimit", ?NULL, <<M:32>>, ?NULL, <<S:32>>] | BinArgs]);
	order_by ->
            {ColName, Type} = V,
	    query_to_argslist(T, [["setorder", ?NULL, ColName, ?NULL, Type] | BinArgs])
    end;
query_to_argslist([], BinArgs) ->
    lists:reverse(BinArgs).

encode_table(Data) when is_list(Data) ->
    encode_table(Data, []).

encode_table([], Acc) ->
    lists:reverse(Acc);
encode_table([{K, V} | Tail], Acc) ->
    encode_table(Tail, [V | [ K | Acc]]).

decode_table({error, Code}) ->
    {error, Code};
decode_table(Data) when is_list(Data) ->
    decode_table(Data, []).

decode_table([], Acc) ->
    lists:reverse(Acc);
decode_table([K, V | Tail], Acc) ->
    decode_table(Tail, [{K, V} | Acc]).
