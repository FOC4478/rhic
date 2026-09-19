const express = require("express");

const {
  approveOrder,
  rejectOrder,
} = require("../controllers/paymentController");

const router = express.Router();

// Approve a bookstore payment
router.post("/orders/approve", approveOrder);

// Reject a bookstore payment
router.post("/orders/reject", rejectOrder);

module.exports = router;