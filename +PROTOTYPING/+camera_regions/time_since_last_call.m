function elapsed = time_since_last_call()

persistent last_call;

if isempty(last_call)
    last_call = clock; 
end

elapsed = etime(clock,last_call) * 1000;

last_call = clock;


end

