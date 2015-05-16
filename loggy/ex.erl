-module(ex).
-export([create/1,update/2,safeprint/2, sum/1,log/1]).

create(L)->
		lists:map(fun(X)->{X,0} end,L).

update(Name,List)->
	case lists:keyfind(Name, 1, List) of
		{_, Value} ->
			Temp = lists:keydelete(Name, 1, List),
		  	lists:append([{Name,Value+1}], Temp);
			%Value+1;
			%Lamport_list;
		false ->
			500
	end.

safeprint(Min,Sorted)->
	case Sorted of
		[{Name,Time,{Action,{Msg,Id}}}|T]=Sorted->
			if Time=<Min ->
				%New = [{Name,Time,{Action,{Msg,Id}}}],
				%New = [{Name,Time,{Msg,Id}}],
				lists:delete([{Name,Time,{Action,{Msg,Id}}}], Sorted),
				New = [{Name,Time,{Action,{Msg,Id}}}],
				log(New),
				safeprint(Min,T);
		  	true ->
				safeprint(Min,T)
			end;
		[]->
			io:format("Wait to receive messages...")
		end.


log(Stor) ->
	case Stor of
		[{From, Time, Msg}|T]->
	io:format("log: ~w ~w ~p~n", [From, Time, Msg]),
		log(T);
		[] ->
			io:format("")
	end.



sum(L)->
	case L of
		[] ->
			0;
		[H|T] ->
			H + sum(T)
	end.