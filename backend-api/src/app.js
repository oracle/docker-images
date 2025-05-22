// In backend-api/src/app.js
const express = require('express');
const app = express();

// Import routes
const authRoutes = require('./routes/auth.routes');
const vacationRoutes = require('./routes/vacation.routes');

app.use(express.json()); // Middleware to parse JSON bodies

// Placeholder Authentication Middleware (applied selectively in routes)
const authMiddleware = (req, res, next) => {
  console.log('Auth middleware placeholder hit');
  // In a real app, you'd verify a token here
  // For now, let's assume req.user might be populated by a real auth process
  // req.user = { id: 'mockUserId', role: 'employee' }; // Example
  next();
};

// Routes
app.get('/', (req, res) => {
  res.send('Vacation Request API is running!');
});

app.use('/api/auth', authRoutes);
app.use('/api/vacation-requests', vacationRoutes); // All vacation routes will be authenticated

// Basic error handling
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).send('Something broke!');
});

module.exports = app;
