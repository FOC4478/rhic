const {
  getFirestore,
} = require("firebase-admin/firestore");

const {
  sendNotificationToMember,
  sendNotificationToAllMembers,
  deleteUserNotification,
} = require("../services/notificationService");

// ============================================================
// FIRESTORE
// ============================================================
//
// IMPORTANT:
// Do not call getFirestore() at file-load time.
// server.js initializes Firebase Admin first.
//

function getDb() {
  return getFirestore();
}

// ============================================================
// VALIDATION HELPERS
// ============================================================

function normalizeString(
  value,
  maxLength,
) {
  if (typeof value !== "string") {
    return "";
  }

  return value.trim().substring(
    0,
    maxLength,
  );
}

function normalizeData(data) {
  if (!data || typeof data !== "object") {
    return {};
  }

  const result = {};

  for (const [key, value] of Object.entries(data)) {
    if (
      typeof key !== "string" ||
      key.trim().length === 0
    ) {
      continue;
    }

    if (
      typeof value === "string" ||
      typeof value === "number" ||
      typeof value === "boolean"
    ) {
      result[key] = String(value);
    }
  }

  return result;
}

// ============================================================
// SEND TO ONE MEMBER
// ============================================================

async function sendToMember(
  req,
  res,
) {
  try {
    const userId =
      normalizeString(
        req.body?.userId,
        128,
      );

    const title =
      normalizeString(
        req.body?.title,
        100,
      );

    const body =
      normalizeString(
        req.body?.body,
        500,
      );

    const type =
      normalizeString(
        req.body?.type,
        100,
      ) || "general";

    const route =
      normalizeString(
        req.body?.route,
        300,
      );

    const imageObjectKey =
      normalizeString(
        req.body?.imageObjectKey,
        1000,
      );

    const data =
      normalizeData(
        req.body?.data,
      );

    // --------------------------------------------------------
    // VALIDATION
    // --------------------------------------------------------

    if (!userId) {
      return res.status(400).json({
        success: false,
        message:
          "A member user ID is required.",
      });
    }

    if (!title) {
      return res.status(400).json({
        success: false,
        message:
          "Notification title is required.",
      });
    }

    if (!body) {
      return res.status(400).json({
        success: false,
        message:
          "Notification body is required.",
      });
    }

    // --------------------------------------------------------
    // CHECK MEMBER
    // --------------------------------------------------------

    const db = getDb();

    const userSnapshot =
      await db
        .collection("users")
        .doc(userId)
        .get();

    if (!userSnapshot.exists) {
      return res.status(404).json({
        success: false,
        message:
          "Member account was not found.",
      });
    }

    const userData =
      userSnapshot.data() || {};

    if (userData.role !== "member") {
      return res.status(400).json({
        success: false,
        message:
          "Notifications can only be sent to members.",
      });
    }

    if (
      userData.accountStatus !==
      "active"
    ) {
      return res.status(400).json({
        success: false,
        message:
          "This member account is not active.",
      });
    }

    // --------------------------------------------------------
    // SEND NOTIFICATION
    // --------------------------------------------------------

    const result =
      await sendNotificationToMember({
        userId,
        title,
        body,
        type,
        route: route || null,
        imageObjectKey:
          imageObjectKey || null,
        data,
      });

    return res.status(200).json({
      success: true,
      message:
        "Notification processed successfully.",
      result,
    });
  } catch (error) {
    console.error(
      "Send-to-member notification error:",
      error,
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to send notification to member.",
    });
  }
}

// ============================================================
// SEND TO ALL MEMBERS
// ============================================================

async function sendToAllMembers(
  req,
  res,
) {
  try {
    const title =
      normalizeString(
        req.body?.title,
        100,
      );

    const body =
      normalizeString(
        req.body?.body,
        500,
      );

    const type =
      normalizeString(
        req.body?.type,
        100,
      ) || "general";

    const route =
      normalizeString(
        req.body?.route,
        300,
      );

    const imageObjectKey =
      normalizeString(
        req.body?.imageObjectKey,
        1000,
      );

    const data =
      normalizeData(
        req.body?.data,
      );

    // --------------------------------------------------------
    // VALIDATION
    // --------------------------------------------------------

    if (!title) {
      return res.status(400).json({
        success: false,
        message:
          "Notification title is required.",
      });
    }

    if (!body) {
      return res.status(400).json({
        success: false,
        message:
          "Notification body is required.",
      });
    }

    // --------------------------------------------------------
    // SEND
    // --------------------------------------------------------

    const result =
      await sendNotificationToAllMembers({
        title,
        body,
        type,
        route: route || null,
        imageObjectKey:
          imageObjectKey || null,
        data,
      });

    return res.status(200).json({
      success: true,
      message:
        "Notification broadcast processed successfully.",
      result,
    });
  } catch (error) {
    console.error(
      "Send-to-all notification error:",
      error,
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to send notification to members.",
    });
  }
}

// ============================================================
// DELETE NOTIFICATION
// ============================================================

async function deleteNotification(
  req,
  res,
) {
  try {
    const userId =
      normalizeString(
        req.params.userId,
        128,
      );

    const notificationId =
      normalizeString(
        req.params.notificationId,
        128,
      );

    if (!userId) {
      return res.status(400).json({
        success: false,
        message:
          "User ID is required.",
      });
    }

    if (!notificationId) {
      return res.status(400).json({
        success: false,
        message:
          "Notification ID is required.",
      });
    }

    await deleteUserNotification({
      userId,
      notificationId,
    });

    return res.status(200).json({
      success: true,
      message:
        "Notification deleted successfully.",
    });
  } catch (error) {
    console.error(
      "Delete notification error:",
      error,
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to delete notification.",
    });
  }
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  sendToMember,
  sendToAllMembers,
  deleteNotification,
};