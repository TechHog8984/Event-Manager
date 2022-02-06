local CreateEvent = require'src';
local Event = CreateEvent{Name = 'Orangutan'};

local Connection1 = Event:Connect(function(Key, ...)
  if Key == 'Key' then
    print('Passed: ', ...);
  else
    print('Invalid key.');
  end;
end);
Event:Fire('Key', 'Execute', 'Permission=true');
Event:Fire('bruh', 'Execute');
Connection1:Disconnect();
Event:Fire('Key', 'Clear', 'All');

Event:Connect(function(...)
  print('Con1:', ...);
end);
Event:Connect(function(...)
  print('Con2:', ...);
end);
Event:Connect(function(...)
  print('Con3:', ...);
end);

Event:Fire('Push', 'Array1', 'Value6');
Event:Fire('Pop', 'Array2', 'Value5');

Event:DisconnectAll();

Event:Fire('Pull', 'Array2', 'Value3');
Event:Fire('Get', 'Array2', 'Value9');
