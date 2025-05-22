/**
 * @typedef {object} VacationRequest
 * @property {string} request_id - Primary Key (e.g., UUID)
 * @property {string} user_id - Foreign Key to User model (employee making request)
 * @property {Date} start_date
 * @property {Date} end_date
 * @property {string} [reason] - Optional
 * @property {'pending' | 'approved' | 'rejected' | 'cancelled'} status
 * @property {Date} requested_date - Timestamp of submission
 * @property {string} [approved_by_id] - Foreign Key to User model (supervisor who actioned, nullable)
 * @property {Date} [actioned_date] - Timestamp of approval/rejection (nullable)
 * @property {string} [supervisor_comments] - Optional comments from supervisor
 * @property {Date} created_at - Timestamp
 * @property {Date} updated_at - Timestamp
 */

// Placeholder for actual database model/schema definition
module.exports = {};
