import React, { useState, useEffect, useRef, createContext, useContext } from 'react';
import { Send, Users, Settings, Bell, BellOff, Hash, Lock, Plus, X, UserPlus, LogOut, MessageCircle, Eye, EyeOff } from 'lucide-react';

// Simulated Socket.io functionality (In real app, this would connect to actual Socket.io server)
class MockSocket {
  constructor() {
    this.listeners = {};
    this.connected = false;
    this.id = Math.random().toString(36).substr(2, 9);
  }

  on(event, callback) {
    if (!this.listeners[event]) {
      this.listeners[event] = [];
    }
    this.listeners[event].push(callback);
  }

  emit(event, data) {
    // Simulate server responses
    setTimeout(() => {
      switch (event) {
        case 'join-room':
          this.trigger('user-joined', { roomId: data.roomId, user: data.user });
          break;
        case 'send-message':
          this.trigger('message-received', {
            ...data,
            id: Date.now(),
            timestamp: new Date().toISOString()
          });
          break;
        case 'typing':
          this.trigger('user-typing', data);
          break;
        case 'stop-typing':
          this.trigger('user-stop-typing', data);
          break;
      }
    }, 100 + Math.random() * 200);
  }

  trigger(event, data) {
    if (this.listeners[event]) {
      this.listeners[event].forEach(callback => callback(data));
    }
  }

  connect() {
    this.connected = true;
    setTimeout(() => {
      this.trigger('connect', { id: this.id });
    }, 500);
  }

  disconnect() {
    this.connected = false;
    this.trigger('disconnect');
  }
}

// Context for Socket and Chat state
const ChatContext = createContext();

// Custom hook for chat functionality
const useChat = () => {
  const context = useContext(ChatContext);
  if (!context) {
    throw new Error('useChat must be used within ChatProvider');
  }
  return context;
};

// Authentication Component
const AuthForm = ({ onLogin }) => {
  const [username, setUsername] = useState('');
  const [isLoading, setIsLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (!username.trim()) return;
    
    setIsLoading(true);
    setTimeout(() => {
      onLogin({
        id: Math.random().toString(36).substr(2, 9),
        username: username.trim(),
        avatar: `https://api.dicebear.com/7.x/avataaars/svg?seed=${username}`,
        status: 'online'
      });
      setIsLoading(false);
    }, 1000);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-600 to-purple-700 flex items-center justify-center p-4">
      <div className="bg-white rounded-lg shadow-xl p-8 w-full max-w-md">
        <div className="text-center mb-8">
          <MessageCircle className="w-16 h-16 text-blue-600 mx-auto mb-4" />
          <h1 className="text-2xl font-bold text-gray-900">Welcome to ChatFlow</h1>
          <p className="text-gray-600">Enter your username to start chatting</p>
        </div>
        
        <div>
          <div className="mb-6">
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Username
            </label>
            <input
              type="text"
              value={username}
              onChange={(e) => setUsername(e.target.value)}
              onKeyPress={(e) => e.key === 'Enter' && handleSubmit(e)}
              className="w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
              placeholder="Enter your username"
              disabled={isLoading}
            />
          </div>
          
          <button
            onClick={handleSubmit}
            disabled={!username.trim() || isLoading}
            className="w-full bg-blue-600 text-white py-3 
      </div>
    </div>
  );
};

// Room List Component
const RoomList = ({ rooms, activeRoom, onRoomSelect, onCreateRoom, user }) => {
  const [showCreateRoom, setShowCreateRoom] = useState(false);
  const [newRoomName, setNewRoomName] = useState('');
  const [isPrivate, setIsPrivate] = useState(false);

  const handleCreateRoom = (e) => {
    e.preventDefault();
    if (!newRoomName.trim()) return;
    
    onCreateRoom({
      id: Date.now().toString(),
      name: newRoomName.trim(),
      type: isPrivate ? 'private' : 'public',
      members: [user.id],
      createdBy: user.id
    });
    
    setNewRoomName('');
    setIsPrivate(false);
    setShowCreateRoom(false);
  };

  return (
    <div className="w-64 bg-gray-800 text-white flex flex-col">
      <div className="p-4 border-b border-gray-700">
        <h2 className="text-lg font-semibold mb-3">Rooms</h2>
        <button
          onClick={() => setShowCreateRoom(true)}
          className="w-full bg-blue-600 hover:bg-blue-700 text-white py-2 px-3 rounded-lg text-sm flex items-center gap-2 transition-colors"
        >
          <Plus size={16} />
          Create Room
        </button>
      </div>
      
      <div className="flex-1 overflow-y-auto">
        {rooms.map(room => (
          <button
            key={room.id}
            onClick={() => onRoomSelect(room)}
            className={`w-full text-left p-4 hover:bg-gray-700 border-b border-gray-700 transition-colors ${
              activeRoom?.id === room.id ? 'bg-gray-700 border-l-4 border-blue-500' : ''
            }`}
          >
            <div className="flex items-center gap-3">
              {room.type === 'private' ? <Lock size={16} /> : <Hash size={16} />}
              <div className="flex-1 min-w-0">
                <div className="font-medium truncate">{room.name}</div>
                <div className="text-xs text-gray-400">
                  {room.members?.length || 0} members
                </div>
              </div>
            </div>
          </button>
        ))}
      </div>

      {/* Create Room Modal */}
      {showCreateRoom && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
          <div className="bg-white rounded-lg p-6 w-full max-w-md mx-4">
            <div className="flex justify-between items-center mb-4">
              <h3 className="text-lg font-semibold text-gray-900">Create New Room</h3>
              <button
                onClick={() => setShowCreateRoom(false)}
                className="text-gray-500 hover:text-gray-700"
              >
                <X size={20} />
              </button>
            </div>
            
            <form onSubmit={handleCreateRoom}>
              <div className="mb-4">
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Room Name
                </label>
                <input
                  type="text"
                  value={newRoomName}
                  onChange={(e) => setNewRoomName(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent text-gray-900"
                  placeholder="Enter room name"
                />
              </div>
              
              <div className="mb-6">
                <label className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    checked={isPrivate}
                    onChange={(e) => setIsPrivate(e.target.checked)}
                    className="rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                  />
                  <span className="text-sm text-gray-700">Private Room</span>
                </label>
              </div>
              
              <div className="flex gap-3">
                <button
                  type="button"
                  onClick={() => setShowCreateRoom(false)}
                  className="flex-1 bg-gray-300 text-gray-700 py-2 px-4 rounded-lg hover:bg-gray-400 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={!newRoomName.trim()}
                  className="flex-1 bg-blue-600 text-white py-2 px-4 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  Create
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};

// User List Component
const UserList = ({ users, currentUser }) => {
  return (
    <div className="w-64 bg-gray-100 dark:bg-gray-800 border-l border-gray-200 dark:border-gray-700">
      <div className="p-4 border-b border-gray-200 dark:border-gray-700">
        <h3 className="font-semibold text-gray-900 dark:text-white">Online Users</h3>
        <p className="text-sm text-gray-500 dark:text-gray-400">{users.length} online</p>
      </div>
      
      <div className="overflow-y-auto">
        {users.map(user => (
          <div key={user.id} className="p-3 border-b border-gray-200 dark:border-gray-700 last:border-b-0">
            <div className="flex items-center gap-3">
              <div className="relative">
                <img
                  src={user.avatar}
                  alt={user.username}
                  className="w-8 h-8 rounded-full"
                />
                <div className={`absolute -bottom-1 -right-1 w-3 h-3 rounded-full border-2 border-white ${
                  user.status === 'online' ? 'bg-green-500' : 
                  user.status === 'away' ? 'bg-yellow-500' : 'bg-gray-500'
                }`} />
              </div>
              <div className="flex-1 min-w-0">
                <div className="font-medium text-gray-900 dark:text-white truncate">
                  {user.username}
                  {user.id === currentUser.id && <span className="text-xs text-gray-500 ml-1">(You)</span>}
                </div>
                <div className="text-xs text-gray-500 dark:text-gray-400 capitalize">
                  {user.status}
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

// Message Component
const Message = ({ message, currentUser, onMarkAsRead }) => {
  const isOwn = message.userId === currentUser.id;
  const messageTime = new Date(message.timestamp).toLocaleTimeString([], { 
    hour: '2-digit', 
    minute: '2-digit' 
  });

  useEffect(() => {
    if (!isOwn && !message.readBy?.includes(currentUser.id)) {
      setTimeout(() => onMarkAsRead(message.id), 1000);
    }
  }, [message.id, isOwn, message.readBy, currentUser.id, onMarkAsRead]);

  return (
    <div className={`flex gap-3 mb-4 ${isOwn ? 'flex-row-reverse' : ''}`}>
      <img
        src={message.user.avatar}
        alt={message.user.username}
        className="w-8 h-8 rounded-full flex-shrink-0"
      />
      <div className={`flex-1 max-w-xs ${isOwn ? 'items-end' : 'items-start'} flex flex-col`}>
        <div className={`px-4 py-2 rounded-lg ${
          isOwn 
            ? 'bg-blue-600 text-white' 
            : 'bg-gray-200 dark:bg-gray-700 text-gray-900 dark:text-white'
        }`}>
          {!isOwn && (
            <div className="text-xs font-medium mb-1 opacity-75">
              {message.user.username}
            </div>
          )}
          <div className="break-words">{message.text}</div>
        </div>
        <div className={`flex items-center gap-1 mt-1 text-xs text-gray-500 ${isOwn ? 'flex-row-reverse' : ''}`}>
          <span>{messageTime}</span>
          {isOwn && (
            <div className="flex items-center gap-1">
              {message.delivered && <Eye size={12} className="text-gray-400" />}
              {message.readBy && message.readBy.length > 0 && (
                <span className="text-blue-500">Read by {message.readBy.length}</span>
              )}
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

// Typing Indicator Component
const TypingIndicator = ({ typingUsers, currentUser }) => {
  const typers = typingUsers.filter(user => user.id !== currentUser.id);
  
  if (typers.length === 0) return null;

  const getTypingText = () => {
    if (typers.length === 1) {
      return `${typers[0].username} is typing...`;
    } else if (typers.length === 2) {
      return `${typers[0].username} and ${typers[1].username} are typing...`;
    } else {
      return `${typers.length} people are typing...`;
    }
  };

  return (
    <div className="flex items-center gap-2 px-4 py-2 text-sm text-gray-500 italic">
      <div className="flex space-x-1">
        <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0ms' }} />
        <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '150ms' }} />
        <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '300ms' }} />
      </div>
      <span>{getTypingText()}</span>
    </div>
  );
};

// Chat Window Component
const ChatWindow = ({ room, messages, onSendMessage, currentUser, typingUsers, onMarkAsRead }) => {
  const [messageText, setMessageText] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const messagesEndRef = useRef(null);
  const typingTimeoutRef = useRef(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const handleSendMessage = (e) => {
    e.preventDefault();
    if (!messageText.trim()) return;

    onSendMessage({
      roomId: room.id,
      text: messageText.trim(),
      user: currentUser,
      userId: currentUser.id
    });

    setMessageText('');
    setIsTyping(false);
  };

  const handleTyping = (e) => {
    setMessageText(e.target.value);
    
    if (!isTyping) {
      setIsTyping(true);
      // In real app, emit typing event to socket
    }

    // Clear existing timeout
    if (typingTimeoutRef.current) {
      clearTimeout(typingTimeoutRef.current);
    }

    // Set new timeout to stop typing after 1 second of inactivity
    typingTimeoutRef.current = setTimeout(() => {
      setIsTyping(false);
      // In real app, emit stop typing event to socket
    }, 1000);
  };

  if (!room) {
    return (
      <div className="flex-1 flex items-center justify-center bg-gray-50 dark:bg-gray-900">
        <div className="text-center">
          <MessageCircle className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-gray-500 dark:text-gray-400">
            Select a room to start chatting
          </h3>
        </div>
      </div>
    );
  }

  return (
    <div className="flex-1 flex flex-col bg-white dark:bg-gray-900">
      {/* Room Header */}
      <div className="p-4 border-b border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800">
        <div className="flex items-center gap-3">
          {room.type === 'private' ? <Lock size={20} /> : <Hash size={20} />}
          <h2 className="text-lg font-semibold text-gray-900 dark:text-white">{room.name}</h2>
          <span className="text-sm text-gray-500 dark:text-gray-400">
            {room.members?.length || 0} members
          </span>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map(message => (
          <Message
            key={message.id}
            message={message}
            currentUser={currentUser}
            onMarkAsRead={onMarkAsRead}
          />
        ))}
        <TypingIndicator typingUsers={typingUsers} currentUser={currentUser} />
        <div ref={messagesEndRef} />
      </div>

      {/* Message Input */}
      <form onSubmit={handleSendMessage} className="p-4 border-t border-gray-200 dark:border-gray-700">
        <div className="flex gap-2">
          <input
            type="text"
            value={messageText}
            onChange={handleTyping}
            placeholder={`Message ${room.name}`}
            className="flex-1 px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
          />
          <button
            type="submit"
            disabled={!messageText.trim()}
            className="bg-blue-600 text-white p-2 rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          >
            <Send size={20} />
          </button>
        </div>
      </form>
    </div>
  );
};

// Notification Component
const NotificationSystem = ({ notifications, onDismiss }) => {
  return (
    <div className="fixed top-4 right-4 z-50 space-y-2">
      {notifications.map(notification => (
        <div
          key={notification.id}
          className={`p-4 rounded-lg shadow-lg max-w-sm flex items-center gap-3 ${
            notification.type === 'message' ? 'bg-blue-600 text-white' :
            notification.type === 'user-joined' ? 'bg-green-600 text-white' :
            'bg-gray-800 text-white'
          }`}
        >
          <div className="flex-1">
            <div className="font-medium">{notification.title}</div>
            <div className="text-sm opacity-90">{notification.message}</div>
          </div>
          <button
            onClick={() => onDismiss(notification.id)}
            className="text-white hover:text-gray-200"
          >
            <X size={16} />
          </button>
        </div>
      ))}
    </div>
  );
};

// Main Chat Application
const ChatApplication = () => {
  const [user, setUser] = useState(null);
  const [rooms, setRooms] = useState([
    {
      id: '1',
      name: 'General',
      type: 'public',
      members: []
    },
    {
      id: '2',
      name: 'Random',
      type: 'public',
      members: []
    }
  ]);
  const [activeRoom, setActiveRoom] = useState(null);
  const [messages, setMessages] = useState({});
  const [onlineUsers, setOnlineUsers] = useState([]);
  const [typingUsers, setTypingUsers] = useState([]);
  const [notifications, setNotifications] = useState([]);
  const [notificationsEnabled, setNotificationsEnabled] = useState(true);
  const socketRef = useRef(null);

  // Initialize socket connection
  useEffect(() => {
    if (user) {
      socketRef.current = new MockSocket();
      socketRef.current.connect();

      // Add current user to online users
      setOnlineUsers(prev => [...prev, user]);

      // Setup socket event listeners
      socketRef.current.on('message-received', (message) => {
        setMessages(prev => ({
          ...prev,
          [message.roomId]: [...(prev[message.roomId] || []), {
            ...message,
            delivered: true,
            readBy: []
          }]
        }));

        // Show notification for messages in inactive rooms
        if (message.userId !== user.id && message.roomId !== activeRoom?.id && notificationsEnabled) {
          addNotification({
            type: 'message',
            title: `New message in ${rooms.find(r => r.id === message.roomId)?.name}`,
            message: `${message.user.username}: ${message.text}`
          });
        }
      });

      socketRef.current.on('user-joined', (data) => {
        setOnlineUsers(prev => {
          const exists = prev.find(u => u.id === data.user.id);
          return exists ? prev : [...prev, data.user];
        });

        if (data.user.id !== user.id && notificationsEnabled) {
          addNotification({
            type: 'user-joined',
            title: 'User Joined',
            message: `${data.user.username} joined the chat`
          });
        }
      });

      socketRef.current.on('user-typing', (data) => {
        if (data.userId !== user.id) {
          setTypingUsers(prev => {
            const exists = prev.find(u => u.id === data.userId);
            return exists ? prev : [...prev, data.user];
          });
        }
      });

      socketRef.current.on('user-stop-typing', (data) => {
        setTypingUsers(prev => prev.filter(u => u.id !== data.userId));
      });

      return () => {
        if (socketRef.current) {
          socketRef.current.disconnect();
        }
      };
    }
  }, [user]);

  const addNotification = (notification) => {
    const id = Date.now().toString();
    setNotifications(prev => [...prev, { ...notification, id }]);
    
    // Auto dismiss after 5 seconds
    setTimeout(() => {
      setNotifications(prev => prev.filter(n => n.id !== id));
    }, 5000);
  };

  const handleLogin = (userData) => {
    setUser(userData);
  };

  const handleLogout = () => {
    if (socketRef.current) {
      socketRef.current.disconnect();
    }
    setUser(null);
    setActiveRoom(null);
    setMessages({});
    setOnlineUsers([]);
    setTypingUsers([]);
    setNotifications([]);
  };

  const handleRoomSelect = (room) => {
    setActiveRoom(room);
    if (socketRef.current && user) {
      socketRef.current.emit('join-room', { roomId: room.id, user });
    }
  };

  const handleCreateRoom = (roomData) => {
    const newRoom = {
      ...roomData,
      members: [user.id]
    };
    setRooms(prev => [...prev, newRoom]);
    setActiveRoom(newRoom);
  };

  const handleSendMessage = (messageData) => {
    if (socketRef.current) {
      socketRef.current.emit('send-message', messageData);
    }
  };

  const handleMarkAsRead = (messageId) => {
    if (activeRoom) {
      setMessages(prev => ({
        ...prev,
        [activeRoom.id]: (prev[activeRoom.id] || []).map(msg =>
          msg.id === messageId
            ? { ...msg, readBy: [...(msg.readBy || []), user.id] }
            : msg
        )
      }));
    }
  };

  const dismissNotification = (notificationId) => {
    setNotifications(prev => prev.filter(n => n.id !== notificationId));
  };

  if (!user) {
    return <AuthForm onLogin={handleLogin} />;
  }

  return (
    <div className="h-screen flex bg-gray-100 dark:bg-gray-900">
      {/* Room List */}
      <RoomList
        rooms={rooms}
        activeRoom={activeRoom}
        onRoomSelect={handleRoomSelect}
        onCreateRoom={handleCreateRoom}
        user={user}
      />

      {/* Chat Window */}
      <ChatWindow
        room={activeRoom}
        messages={messages[activeRoom?.id] || []}
        onSendMessage={handleSendMessage}
        currentUser={user}
        typingUsers={typingUsers}
        onMarkAsRead={handleMarkAsRead}
      />

      {/* User List */}
      <UserList users={onlineUsers} currentUser={user} />

      {/* Notifications */}
      <NotificationSystem
        notifications={notifications}
        onDismiss={dismissNotification}
      />

      {/* Top Bar with Settings */}
      <div className="fixed top-4 left-4 z-40">
        <div className="flex items-center gap-2 bg-white dark:bg-gray-800 rounded-lg shadow-lg p-2">
          <img
            src={user.avatar}
            alt={user.username}
            className="w-8 h-8 rounded-full"
          />
          <span className="text-sm font-medium text-gray-900 dark:text-white">
            {user.username}
          </span>
          <button
            onClick={() => setNotificationsEnabled(!notificationsEnabled)}
            className={`p-1 rounded ${notificationsEnabled ? 'text-blue-600' : 'text-gray-400'}`}
            title={notificationsEnabled ? 'Disable notifications' : 'Enable notifications'}
          >
            {notificationsEnabled ? <Bell size={16} /> : <BellOff size={16} />}
          </button>
          <button
            onClick={handleLogout}
            className="p-1 text-red-600 hover:text-red-700"
            title="Logout"
          >
            <LogOut size={16} />
          </button>
        </div>
      </div>
    </div>
  );
};

// Chat Provider Component
const ChatProvider = ({ children }) => {
  return (
    <ChatContext.Provider value={{}}>
      {children}
    </ChatContext.Provider>
  );
};

// Main App Component
const App = () => {
  return (
    <ChatProvider>
      <ChatApplication />
    </ChatProvider>
  );
};

export default App;