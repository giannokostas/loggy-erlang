-module(worker).
-export([start/6, stop/1, peers/2 , new/2, increase/2 , check/3 , update/3 , loop/6]).

start(Name, Logger, Seed, Sleep, Jitter, Workers) ->
	spawn_link(fun() -> init(Name, Logger, Seed, Sleep, Jitter,Workers) end).

stop(Worker) ->
	Worker ! stop.

init(Name, Log, Seed, Sleep, Jitter, Workers) ->
	% we With the command below we can start all workers and 
	% then inform them who their peers are.
	%logger:init(lists:map(fun(X)->{X,0} end,L)).
	Lamport = [{john,0},{paul,0},{ringo,0},{george,0}],
	%Lamport = new(Name , Lamport),
	random:seed(Seed, Seed, Seed),
	receive
	{peers, Peers} ->
		loop(Name, Log, Peers, Sleep, Jitter, Lamport);
	stop ->
		ok
	end.

peers(Wrk, Peers) ->
	Wrk ! {peers, Peers}.

loop(Name, Log, Peers, Sleep, Jitter, Lamport)->
	% The process will Wait for a message from one of its peers
	Wait = random:uniform(Sleep),
	receive
		{msg, Time, Msg} ->
		{New_time,Lamp} = check(Name,Time,Lamport),
		Log ! {log, Name, New_time, {received, Msg}},
		loop(Name, Log, Peers, Sleep, Jitter, Lamp);
	stop ->
		ok;
	Error ->
		Log ! {log, Name, time, {error, Error}}
	% or after a random sleep time select a peer process that is sent a message
	after Wait ->
		Selected = select(Peers),
		{Time,Lamp} = increase(Name,Lamport),
		%Time=na,
		Message = {hello, random:uniform(100)},
		Selected ! {msg, Time, Message},
		jitter(Jitter),
		Log ! {log, Name, Time, {sending, Message}},
		loop(Name, Log, Peers, Sleep, Jitter, Lamp)
	end.

% Introduce a new worker to Lamport List by default value 0
new(Name,Lamport_list)->
	case lists:keyfind(Name,1,Lamport_list) of
		{_,_} ->
			Lamport_list;
		false ->
			lists:append([{Name,0}],Lamport_list)
	end.

% increase the lamport stamp for a worker by 1
increase(Name,Lamport_list)->
	case lists:keyfind(Name, 1, Lamport_list) of
		{_, Value} ->
			Temp = lists:keydelete(Name, 1, Lamport_list),
		  	{Value+1,lists:append([{Name,Value+1}], Temp)};
			%Value+1;
			%Lamport_list;
		false ->
			500
	end.

% for the receiveing messages i have max(Lr,Ls)+1 
check(Name,Receive,Lamport_list)->
	case lists:keyfind(Name, 1, Lamport_list) of
		{_, Value} ->
        Max = lists:max([Receive,Value]),
		Temp = lists:keydelete(Name, 1, Lamport_list),
		{Max+1,lists:append([{Name,Max+1}], Temp)};
		%{Max+1,update(Name,Max,Lamport_list)};
		true ->
			Lamport_list
	end.

% Take a max value(stamp) and increase it by 1
update(Name,Stamp,Lamport_list)->
	case lists:keyfind(Name, 1, Lamport_list) of
		{_,_} ->
			Temp = lists:keydelete(Name, 1, Lamport_list),
		  	lists:append([{Name,Stamp+1}], Temp);
		false ->
			Stamp
	end.
	

% select randomly a peer
select(Peers) ->
	% nth->returns the N element , in this case the N element is 
	% a random element of the Peers.
	lists:nth(random:uniform(length(Peers)), Peers).
	jitter(0) -> ok;

% the jitter value will introduce a random delay between the
% sending of a message to  and the sending of a log entry.
jitter(Jitter) -> timer:sleep(random:uniform(Jitter)).
