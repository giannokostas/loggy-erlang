-module(logger).
-export([start/1, stop/1 , store/4, log/1, update/3, safeprint/3]).

start(Nodes) ->
	Table = lists:map(fun(X)->{X,0} end,Nodes),
	spawn_link(fun() ->init(Nodes,Table) end).

stop(Logger) ->
	Logger ! stop.

init(_,Table) ->
	%Table = lists:map(fun(X)->{X,0} end,Nodes),
	loop([],Table).

%The logger receives events
loop(St,Table) ->
	%Wait = random:uniform(5000),
	receive
		{log, From, Time, Msg} ->
			Updated = update(From,Table,Time),
			Sorted = store(From,Time,Msg,St),
			%loop(Sorted,Updated)
			%after Wait te->
		    SortedTable = lists:keysort(2,Updated),
			[H|T] = SortedTable,
			{_,Min} = H,
			%io:format("Table: ~w    Min:  ~w~n",[Updated,Min]),
			
			ListWithoutPrintedMessage  = safeprint(Min,Sorted,Updated),
			loop(ListWithoutPrintedMessage,Updated)
	
	end.

%The logger prints the events on the screen
log(Stor) ->
	case Stor of
		[{From, Time, Msg}|T]->
			io:format("log: ~w ~w ~p~n", [From, Time, Msg]),
			log(T);
		[] ->
			ok
	end.

store(From,Time,Msg,St) ->
	Store = [{From,Time,Msg}]++St,
	lists:keysort(2,Store).

update(Name,Table,Time)->
	case lists:keyfind(Name, 1, Table) of
		{_, Value} ->
			Temp = lists:keydelete(Name, 1, Table),
			lists:append([{Name,Time}], Temp);
		false ->
			500
	end.

safeprint(Min,Sorted,Updated)->
	case Sorted of
		[{Name,Time,{Action,{Msg,Id}}}|T]=Sorted->
			
			case Time=<Min of 
				true ->
					%New = [{Name,Time,{Action,{Msg,Id}}}],
					%New = [{Name,Time,{Msg,Id}}],
					%Deleted = lists:delete([{Name,Time,{Action,{Msg,Id}}}], Sorted),
					Print = [{Name,Time,{Action,{Msg,Id}}}],
					log(Print),
					safeprint(Min,T,Updated);
				false->
					Sorted
			end;
		[]->
			[]
	end.
