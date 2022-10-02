% basic command to run the program and menu of choices
run :-
    write('Flight consultant'),nl,
    write('================='),nl,nl,
    write('1 - Load flight table'),nl,
    write('2 - Flights between cities'),nl,
    write('3 - Best flight between cities'),nl,
    write('0 - Exit Program'),nl,nl,
    write('Choose (0-3): '),
    read(Choice),
    nl,nl,
    run_option(Choice).

% option 1 where user gives the file name with the flight data
run_option(1):-
   write('Give me the name of the file that contains the flight table:'),
   read(FileName),
   copy(FileName,'flightData.pl'), % copying the data of given file to a new one
   nl,write('Flight table loaded'),nl,nl,
   run.

% option 2 where user wants to view all existing flights between two cities
run_option(2):-
    % getting the needed information from the user
    write('Please give the following informations using "".'),nl,nl,
    write('Departure: '),
    read(Dep),
    write('Arrival: '),
    read(Arr),
    write('Day: '),
    read(Day),nl,nl,
    % checking whether or not the file with flight data has been created
    exists_file('flightData.pl') ->(
        % write results
        write('From: '), write(Dep),
        write(' To: '), write(Arr),
        write(' Day: '), write(Day),nl,nl,
        % get all alternative results using the command findall
        % and the predicate route
        findall([Route,DepTime,ArrTime,TotalLength],
             route(Dep,Arr,Day,Route,DepTime,ArrTime,TotalLength),
             Result),
        print_results(Result),
        run
    );
    % case the file with flights' data does not exist
    (write('Please select option 1 first'),nl,nl,run).

% option 3 where user wants to view the best existing flight between two cities
run_option(3):-
    % getting the needed information from the user
    write('Please give the following informations using "".'),nl,nl,
    write('Departure: '),
    read(Dep),
    write('Arrival: '),
    read(Arr),
    write('Day: '),
    read(Day),nl,nl,
    % checking whether or not the file with flight data has been created
    exists_file('flightData.pl') ->(
        % write results
        write('From: '), write(Dep),
        write(' To: '), write(Arr),
        write(' Day: '), write(Day),nl,nl,
        % call best_route to get the best alternative
        best_route(Dep,Arr,Day,BestRoute,DepTime,ArrTime,ShortestLength),
        print_best_results(BestRoute,DepTime,ArrTime,ShortestLength),
        run
    );
    % case the file with flights' data does not exist
    (write('Please select option 1 first'),nl,nl,run).

% option 0 where users wants to exit the program
run_option(0):-
    write('Thank you for using the program!'),nl,
    % if it is not the first chosen option we delete the file we created earlier for the flight data
    exists_file('flightData.pl') -> delete_file('flightData.pl') ; true.

% for any other given option we return a message and print the menu again
run_option(_):-
    write('Please select a number between 0 and 3!'),nl,nl,
    run.

% used to copy data from one file to another
copy(File1,File2) :-
    open(File1,read,Stream1),
    open(File2,append,Stream2),
    copy_stream_data(Stream1,Stream2),
    close(Stream1),
    close(Stream2).

% used to convert given time format to minutes
time_to_min(Time,Min) :-
    % remove '-' from time format
    % and get hour and minutes
    split_string(Time,"-","",[Hours,Mins]),
    % convert strings to integers
    atom_number(Hours,H),
    atom_number(Mins,M),
    % convert given time to minutes
    Min is (H*60)+M.

% used to check if 2 given times have a difference
% of at least 40 minutes
is_40min(ArrTime, DeptTime):-
    % convert given times to minutes
    time_to_min(ArrTime,ArrMin),
    time_to_min(DeptTime,DeptMin),
    % return true or false depending on their difference
    ArrMin =< (DeptMin - 40) -> true ; false.

% used to the results included in list Route
write_route([]).
write_route([Route|T]):-
    % get the needed informations in variables
    nth0(0,Route,Dep),
    nth0(1,Route,Arr),
    nth0(2,Route,DepTime),
    nth0(3,Route,ArrTime),
    nth0(4,Route,ID),
    % write the results with proper messages
    write('    '), write(Dep), write(' -> '),
    write(Arr), write('('),
    write(ID),write(') '),
    write('dep: '),
    write_time(DepTime),
    write(' arr: '),
    write_time(ArrTime), nl,
    % call the write_route recursively for the rest members of the list
    write_route(T).

% used to write time in the right format
write_time(Time):-
    % seperate hours from minutes
    split_string(Time,"-","",[Hours, Mins]),
    % write the time in the asked format
    write(Hours), write(':'),
    write(Mins).

% used to print the results from route
print_results([]).
print_results([H|T]):-
    % get the needed informations in variables
    nth0(0,H,Route),
    nth0(1,H,DepTime),
    nth0(2,H,ArrTime),
    nth0(3,H,TotalLength),
    % write the results with proper messages
    % and call specific predicates where needed
    write('Route:'),nl,
    write_route(Route),
    write('Total Route: Departure: '),
    write_time(DepTime),
    write(' Arrival: '),
    write_time(ArrTime),
    write(' Flight length: '),
    write(TotalLength),
    write(' min'), nl, nl,
    % call the print_results recursively for the rest members of the list
    print_results(T).

% used to print the results from best_route
print_best_results(BestRoute,DepTime,ArrTime,ShortestLength):-
    % write the results with proper messages
    % and call specific predicates where needed
    write('Best Route:'),nl,
    write_route(BestRoute),
    write('Total Route: Departure: '),
    write_time(DepTime),
    write(' Arrival: '),
    write_time(ArrTime),
    write(' Flight length: '),
    write(ShortestLength),
    write(' min'), nl, nl.

% used to make route work with added arguments
% Visited: a list with every place we have visited to get
% from place1 to place2
% RoutePath: a list of lists holding the same information
% as Route but reversed
route_impl(Place2,Place2,Visited,_Day,RoutePath,Route,DeptTime,ArrTime,TotalLength):-
    % checking if there is a gap between flights of at least 40 minutes
    check_flights(RoutePath),!,
    % give value to ArrTime taken from RoutePath
    RoutePath = [H|_],!,
    nth0(3,H,ArrTime),
    % reverse RoutePath to get the right order in Route
    reverse(RoutePath,Route),!.

% used to make route work with added arguments and also using recursion
% Visited: a list with every place we have visited to get
% from place1 to place2
% Path: a list of lists holding the same information
% as Route but reversed
route_impl(Place1,Place2,Visited,Day,Path,Route,DeptTime,ArrTime,TotalLength):-
    % checking if we should in the other rule or not
    Place1\=Place2,
    % searching for a between flight
    flight(Place1,PlaceStation,DeptTime,ArrTimeStation,ID,Days),
    % checking if the day is the right one
    member(Day, Days),
    % checking that we haven't visited this place already
    not(member(PlaceStation,Visited)),
    % put the informations we need in RoutePath list
    RoutePath = [Place1,PlaceStation,DeptTime,ArrTimeStation,ID],
    % call recursively route_impl to get the rest between flights
    % add the visited place to list Visited
    % add the running RoutePath to the Path list
    route_impl(PlaceStation,Place2,[Place1|Visited],Day,[RoutePath|Path],Route,
               _DeptTimeStation,ArrTime,TotalLength).

% used to check if there is a gap between flights
% of at least 40 minutes
check_flights([_X]):- true,!.
check_flights([Route1,Route2|T]):-
    % comparing the 2 first elements of the list
    nth0(2,Route1,DeptTime),
    nth0(3,Route2,ArrTime),
    % checking the difference
    is_40min(ArrTime,DeptTime),
    % call check_flights recursively for the rest of the given flights
    check_flights([Route2|T]).

% used to return all the alternatives of flights that exist to get from
% place1 to place2 on the given day
route(Place1,Place2,Day,Route,DeptTime,ArrTime,TotalLength):-
    % load the file that was made by the file(s) user gave
    [flightData],
    % call route_impl to get the results
    % add Place1 to the list as a visited place
    route_impl(Place1,Place2,[Place1],Day,[],Route,DeptTime,ArrTime,TotalLength),
    % convert departure and arrival time to minutes
    time_to_min(DeptTime,DeptMin),
    time_to_min(ArrTime,ArrMin),
    % calculate the total length of the flights
    TotalLength is ArrMin-DeptMin.

% used to return the best alternative of flights that exist to get from
% place1 to place2 on the given day
best_route(Place1,Place2,Day,BestRoute,DeptTime,ArrTime,ShortestLength):-
    % get all the alternative resuluts using the command findall
    findall([R,DT,AT,TL], route(Place1,Place2,Day,R,DT,AT,TL), Results),
    % call min_length to get the list with the shortest length of the results
    min_length(Results,MinList),
    % give values to the arguments according to the MinList
    nth0(0,MinList,BestRoute),
    nth0(1,MinList,DeptTime),
    nth0(2,MinList,ArrTime),
    nth0(3,MinList,ShortestLength).

% used to get a list with the results with the shortest length
min_length([X],X).
% case the first result is smaller
min_length([H1,H2|T],Min):-
    % get the value of the length from each result
    nth0(3,H1,Length1),
    nth0(3,H2,Length2),
    % compare the 2 values
    Length1=<Length2,
    % keep the result with the smallest length
    min_length([H1|T],Min),!.
% case the second result is smaller
min_length([H1,H2|T],Min):-
    % get the value of the length from each result
    nth0(3,H1,Length1),
    nth0(3,H2,Length2),
    % compare the 2 values
    Length1>Length2,
    % keep the result with the smallest length
    min_length([H2|T],Min),!.
