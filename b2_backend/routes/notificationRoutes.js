const express = require("express");

const {
  sendToMember,
  sendToAllMembers,
  deleteNotification,
} = require("../controllers/notificationController");

const router = express.Router();

router.post("/send-member", sendToMember);

router.post("/send-all", sendToAllMembers);

router.delete("/:userId/:notificationId", deleteNotification);

module.exports = router;