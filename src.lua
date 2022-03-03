local newproxy = newproxy or function()return{}end;
local spawn = task and task.spawn;
local wrap = coroutine and coroutine.wrap;

local EventHolders = {};
local ConnectionHolders = {};
local EventProperties = {
	__type = {
		readonly = true,
		default = 'Event',
		type = 'string',
	},
	Connections = {
		readonly = true,
		type = 'table',
	},
	Name = {
		readonly = false,
		default = 'Event',
		type = 'string',
	},
	Connect = {
		readonly = true,
		type = 'function',
	},
	Fire = {
		readonly = true,
		type = 'function',
	},
	DisconnectAll = {
		readonly = true,
		type = 'function',
	},
};
local ConnectionProperties = {
	__type = {
		readonly = true,
		default = 'Connection',
		type = 'string',
	},
	Function = {
		readonly = true,
		type = 'function',
	},
	Active = {
		readonly = false,
		default = true,
		type = 'boolean',
	},
	Event = {
		readonly = true,
		type = 'Event',
	},
	Disconnect = {
		readonly = true,
		type = 'function',
	}
}

local function TypeOf(Object)
	local OG = typeof(Object);

	if OG == 'userdata' or OG == 'table' then
		if Object.__type then
			return Object.__type;
		end;
	end;

	return OG;
end;
local function SecureCall(func, ...)

end;

local function Connection__Index(Connection, Index)
	if Connection and ConnectionHolders[Connection] then
		local Holder = ConnectionHolders[Connection];

		return Holder[Index];
	else
		return error('[Connection__index]: Failed to get connection / holder', 2);
	end;
end;
local function Connection__NewIndex(Connection, Index, Value)
	if Connection and ConnectionHolders[Connection] then
		local Holder = ConnectionHolders[Connection];

		if ConnectionProperties[Index] then
			if not ConnectionProperties[Index].readonly then
				Holder[Index] = Value;
				return true;
			else
				return error('[Connection__newindex]: ' .. tostring(Index) .. ' is readonly!', 2);
			end;
		else
			return error('[Connection__newindex]: ' .. tostring(Index) .. ' is not a valid property.', 2);
		end;
	else
		return error('[Connection__newindex]: Failed to get connection / holder', 2);
	end;
end;
local function Connection__Tostring(Connection)
	if Connection and ConnectionHolders[Connection] then
		local Holder = ConnectionHolders[Connection];
		return Holder.Name or error('[Connection__tostring]: Failed to get connection name', 2);
	else
		return error('[Connection__tostring]: Failed to get connection / holder', 2);
	end;
end;

local function ConnectionDisconnect(Connection)
	if Connection and TypeOf(Connection) == 'Connection' and ConnectionHolders[Connection] then
		if Connection.Event and Connection.Event.Connections then
			local index = table.find(Connection.Event.Connections, Connection);
			if index then
				Connection.Event.Connections[index] = nil;
			end;

			Connection.Active = false;
			local Holder = ConnectionHolders[Connection];
			ConnectionHolders[Connection] = nil;
			Holder.Function = nil;
			Holder.Event = nil;
		else
			return error('[[ConnectionDisconnect]: Failed to get Connection Event', 2);
		end;
	else
		return error('[ConnectionDisconnect]: Failed to get Connection / holder', 2);
	end;
end;

ConnectionProperties.Disconnect.default = ConnectionDisconnect;

local function CreateConnection(Event, Function)
	if Event and TypeOf(Event) == 'Event' then
		if Function and type(Function) == 'function' then
			local Connection = newproxy(true);
			local Holder = {
				Event = Event,
				Function = Function,
			};

			ConnectionHolders[Connection] = Holder;

			for Property, Info in next, ConnectionProperties do
				if Info and Info.default then
					Holder[Property] = Info.default;
				end;
			end;

			local MT = getmetatable(Connection);
			MT.__metatable = 'Locked metatable';
			MT.__index = Connection__Index;
			MT.__newindex = Connection__NewIndex;
			MT.__tostring = Connection__Tostring;

			return Connection;
		else
			return error('[CreateConnection]: Expected function, got', tostring(Function), 2);
		end;
	else
		return error('[CreateConnection]: Expected Event, got ', tostring(Event), 2);
	end;
end;

local function Event__Index(Event, Index)
	if Event and EventHolders[Event] then
		local Holder = EventHolders[Event];

		return Holder[Index];
	else
		return error('[Event__index]: Failed to get event / holder', 2);
	end;
end;
local function Event__NewIndex(Event, Index, Value)
	if Event and EventHolders[Event] then
		local Holder = EventHolders[Event];

		if EventProperties[Index] then
			if not EventProperties[Index].readonly then
				Holder[Index] = Value;
				return true;
			else
				return error('[Event__newindex]: ' .. tostring(Index) .. ' is readonly!', 2);
			end;
		else
			return error('[Event__newindex]: ' .. tostring(Index) .. ' is not a valid property.', 2);
		end;
	else
		return error('[Event__newindex]: Failed to get event / holder', 2);
	end;
end;
local function Event__Tostring(Event)
	if Event and EventHolders[Event] then
		local Holder = EventHolders[Event];
		return Holder.Name or error('[__tostring]: Failed to get event name', 2);
	else
		return error('[Event__tostring]: Failed to get event / holder', 2);
	end;
end;

local function EventConnect(Event, Function)
	if Event and TypeOf(Event) == 'Event' then
		if Function and type(Function) == 'function' then
			local Connection = CreateConnection(Event, Function);
			table.insert(Event.Connections, Connection);

			return Connection;
		else
			return error('[EventConnect]: Expected function, got ' .. tostring(Function), 2);
		end;
	else
		return error('[EventConnect]: Failed to get event', 2);
	end;	
end;
local function EventFire(Event, ...)
	if Event and TypeOf(Event) == 'Event' then
		for I, Connection in next, Event.Connections do
			if Connection and ConnectionHolders[Connection] and TypeOf(Connection) == 'Connection' and Connection.Active and Connection.Function then
				local Success, Result;
				if spawn then
					Success, Result = pcall(spawn, Connection.Function, ...);
				elseif wrap then
					Success, Result = pcall(wrap(Connection.Function), ...);
				end;

				if not Success and Result then
					return error('[EventFire, returned from calling Connection.Function]: ' .. tostring(Result));
				end;
			end;
		end;
	else
		return error('[EventFire]: Failed to get event', 2);
	end;
end;
local function EventDisconnectAll(Event)
	if Event and TypeOf(Event) == 'Event' then
		for I, Connection in next, Event.Connections do
			if Connection and TypeOf(Connection) == 'Connection' and Connection.Disconnect then
				local Success, Result;
				if spawn then
					Success, Result = pcall(spawn, Connection.Disconnect, Connection);
				elseif wrap then
					Success, Result = pcall(wrap(Connection.Disconnect), Connection);
				end;

				if not Success and Result then
					return error('[EventDisconnectAll, returned from calling Connection.Disconnect]: ' .. tostring(Result));
				end;
			end;
		end;
	else
		return error('[EventDisconnectAll]: Failed to get event', 2);
	end;
end;

EventProperties.Connect.default = EventConnect;
EventProperties.Fire.default = EventFire;
EventProperties.DisconnectAll.default = EventDisconnectAll;

local function CreateEvent(Info)
	local Event = newproxy(true);
	local Holder = {
		Connections = {},
	};
	EventHolders[Event] = Holder;

	for Property, Info in next, EventProperties do
		if Info and Info.default then
			Holder[Property] = Info.default;
		end;
	end;

	local MT = getmetatable(Event);
	MT.__metatable = 'Locked metatable';
	MT.__index = Event__Index;
	MT.__newindex = Event__NewIndex;
	MT.__tostring = Event__Tostring;

	Event.Name = (Info and Info.Name) or EventProperties.Name.default;

	return Event;
end;

return CreateEvent;
