/**
 * @typedef {object} User
 * @property {string} user_id - Primary Key (e.g., UUID)
 * @property {string} [employee_id_internal] - Internal employee identifier (optional)
 * @property {string} first_name
 * @property {string} last_name
 * @property {string} email - Unique, used for login
 * @property {string} password_hash - Hashed password
 * @property {'employee' | 'supervisor' | 'admin'} role
 * @property {string} location_id - Foreign Key to Location model
 * @property {string} [supervisor_id] - Foreign Key to User model (employee's supervisor, nullable)
 * @property {Date} created_at - Timestamp
 * @property {Date} updated_at - Timestamp
 */

// Placeholder for actual database model/schema definition
// For now, this file serves as documentation for the User structure.
module.exports = {};
