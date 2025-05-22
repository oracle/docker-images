// In backend-api/src/routes/vacation.routes.js
const express = require('express');
const router = express.Router();
const vacationController = require('../controllers/vacation.controller');

// Placeholder Authentication Middleware
const authMiddleware = (req, res, next) => {
  console.log('Auth middleware placeholder hit for /api/vacation-requests');
  // Simulate user authentication for now
  // In a real app, this would verify a JWT or session
  // req.user = { id: 'mockUserId123', role: 'employee', location_id: 'loc1' }; // Example employee
  // req.user = { id: 'mockSupervisorId456', role: 'supervisor', location_id: 'loc1' }; // Example supervisor
  next();
};

// Apply auth middleware to all vacation routes
router.use(authMiddleware);

router.post('/', vacationController.submitRequest);
router.get('/employee', vacationController.getEmployeeRequests); // Gets requests for the logged-in employee
router.get('/supervisor', vacationController.getSupervisorRequests); // Gets requests for the logged-in supervisor
router.put('/:id/approve', vacationController.approveRequest); // Supervisor action
router.put('/:id/reject', vacationController.rejectRequest);   // Supervisor action

module.exports = router;
