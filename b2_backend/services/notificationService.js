const crypto = require("crypto");

const {
  getMessaging,
} = require("firebase-admin/messaging");

const {
  FieldValue,
  getFirestore,
} = require("firebase-admin/firestore");

// ============================================================
// FIREBASE SERVICES
// ============================================================
//
// IMPORTANT:
// Do NOT initialize getFirestore() / getMessaging() at the
// top level.
//
// server.js initializes Firebase Admin first.
// These helpers are called only after that initialization.
//

function getDb() {
  return getFirestore();
}

function getFcmMessaging() {
  return getMessaging();
}

// ============================================================
// CONSTANTS
// ============================================================

const MAX_FCM_TOKENS = 500;

const INVALID_TOKEN_ERROR_CODES = new Set([
  "messaging/registration-token-not-registered",
  "messaging/invalid-registration-token",
]);

// ============================================================
// HELPERS
// ============================================================

function createNotificationId() {
  return crypto.randomUUID();
}

function normalizeString(value, maxLength = 1000) {
  if (typeof value !== "string") {
    return "";
  }

  return value.trim().substring(0, maxLength);
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
// GET USER DEVICE TOKENS
// ============================================================

async function getUserDeviceTokens(userId) {
  const db = getDb();

  const snapshot = await db
    .collection("users")
    .doc(userId)
    .collection("devices")
    .get();

  const devices = [];

  for (const doc of snapshot.docs) {
    const data = doc.data() || {};

    const token =
      typeof data.token === "string"
        ? data.token.trim()
        : "";

    if (!token) {
      continue;
    }

    devices.push({
      documentId: doc.id,
      token,
      platform:
        typeof data.platform === "string"
          ? data.platform
          : "unknown",
    });
  }

  return devices;
}

// ============================================================
// DELETE INVALID DEVICE TOKEN
// ============================================================

async function deleteInvalidDeviceToken(
  userId,
  deviceDocumentId,
) {
  try {
    const db = getDb();

    await db
      .collection("users")
      .doc(userId)
      .collection("devices")
      .doc(deviceDocumentId)
      .delete();

    return true;
  } catch (error) {
    console.error(
      `Unable to delete invalid device token ${deviceDocumentId}:`,
      error.message,
    );

    return false;
  }
}

// ============================================================
// CREATE FIRESTORE NOTIFICATION
// ============================================================

async function createFirestoreNotification({
  userId,
  title,
  body,
  type = "general",
  route = null,
  imageObjectKey = null,
  data = {},
}) {
  const db = getDb();

  const notificationId = createNotificationId();

  const cleanType =
    normalizeString(type, 100) || "general";

  const notificationData = {
    id: notificationId,
    userId,
    title: normalizeString(title, 200),
    body: normalizeString(body, 2000),

    // IMPORTANT:
    // Notification type is stored directly on the
    // notification document.
    //
    // Examples:
    // payment
    // event
    // sermon
    // book
    // community
    // giving
    // announcement
    // general

    type: cleanType,

    read: false,

    createdAt:
      FieldValue.serverTimestamp(),

    data: normalizeData(data),
  };

  // ----------------------------------------------------------
  // ROUTE
  // ----------------------------------------------------------

  if (
    typeof route === "string" &&
    route.trim().length > 0
  ) {
    notificationData.route =
      route.trim();
  }

  // ----------------------------------------------------------
  // B2 IMAGE OBJECT KEY
  // ----------------------------------------------------------
  //
  // IMPORTANT:
  // Store the B2 object key only.
  //
  // NEVER store a signed URL here.
  //

  if (
    typeof imageObjectKey === "string" &&
    imageObjectKey.trim().length > 0
  ) {
    notificationData.imageObjectKey =
      imageObjectKey.trim();
  }

  await db
    .collection("users")
    .doc(userId)
    .collection("notifications")
    .doc(notificationId)
    .set(notificationData);

  return notificationId;
}

// ============================================================
// SEND NOTIFICATION TO USER DEVICES
// ============================================================

async function sendToUserDevices({
  userId,
  title,
  body,
  type = "general",
  route = null,
  imageObjectKey = null,
  data = {},
}) {
  const cleanUserId =
    normalizeString(userId, 200);

  const cleanTitle =
    normalizeString(title, 200);

  const cleanBody =
    normalizeString(body, 2000);

  const cleanType =
    normalizeString(type, 100) || "general";

  if (!cleanUserId) {
    throw new Error(
      "User ID is required.",
    );
  }

  if (!cleanTitle) {
    throw new Error(
      "Notification title is required.",
    );
  }

  if (!cleanBody) {
    throw new Error(
      "Notification body is required.",
    );
  }

  // ----------------------------------------------------------
  // GET USER DEVICES
  // ----------------------------------------------------------

  const devices =
    await getUserDeviceTokens(
      cleanUserId,
    );

  // ----------------------------------------------------------
  // ALWAYS CREATE FIRESTORE NOTIFICATION
  // ----------------------------------------------------------

  const notificationId =
    await createFirestoreNotification({
      userId: cleanUserId,
      title: cleanTitle,
      body: cleanBody,
      type: cleanType,
      route,
      imageObjectKey,
      data,
    });

  // ----------------------------------------------------------
  // NO DEVICES
  // ----------------------------------------------------------

  if (devices.length === 0) {
    return {
      userId: cleanUserId,
      notificationCreated: true,
      notificationId,
      sent: 0,
      failed: 0,
      invalidTokensRemoved: 0,
      totalDevices: 0,
    };
  }

  let sent = 0;
  let failed = 0;
  let invalidTokensRemoved = 0;

  const messaging = getFcmMessaging();

  // ----------------------------------------------------------
  // FCM ALLOWS MAXIMUM 500 TOKENS PER MULTICAST
  // ----------------------------------------------------------

  for (
    let start = 0;
    start < devices.length;
    start += MAX_FCM_TOKENS
  ) {
    const batch =
      devices.slice(
        start,
        start + MAX_FCM_TOKENS,
      );

    const tokens =
      batch.map(
        (device) => device.token,
      );

    // --------------------------------------------------------
    // FCM DATA
    // --------------------------------------------------------

    const fcmData = {
      notificationId,
      type: cleanType,
    };

    // --------------------------------------------------------
    // ROUTE
    // --------------------------------------------------------

    if (
      typeof route === "string" &&
      route.trim().length > 0
    ) {
      fcmData.route =
        route.trim();
    }

    // --------------------------------------------------------
    // IMAGE OBJECT KEY
    // --------------------------------------------------------

    if (
      typeof imageObjectKey === "string" &&
      imageObjectKey.trim().length > 0
    ) {
      fcmData.imageObjectKey =
        imageObjectKey.trim();
    }

    // --------------------------------------------------------
    // EXTRA DATA
    // --------------------------------------------------------

    const normalizedExtraData =
      normalizeData(data);

    Object.assign(
      fcmData,
      normalizedExtraData,
    );

    // --------------------------------------------------------
    // SEND FCM
    // --------------------------------------------------------

    try {
      const response =
        await messaging.sendEachForMulticast({
          tokens,

          notification: {
            title: cleanTitle,
            body: cleanBody,
          },

          data: fcmData,

          android: {
            priority: "high",

            notification: {
              channelId:
                "rhic_notifications",
              sound: "default",
            },
          },

          apns: {
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
        });

      sent += response.successCount;
      failed += response.failureCount;

      // ------------------------------------------------------
      // REMOVE INVALID TOKENS
      // ------------------------------------------------------

      const cleanupPromises = [];

      for (
        let index = 0;
        index < response.responses.length;
        index++
      ) {
        const sendResponse =
          response.responses[index];

        if (sendResponse.success) {
          continue;
        }

        const error =
          sendResponse.error;

        const errorCode =
          error?.code;

        if (
          INVALID_TOKEN_ERROR_CODES.has(
            errorCode,
          )
        ) {
          const device =
            batch[index];

          cleanupPromises.push(
            deleteInvalidDeviceToken(
              cleanUserId,
              device.documentId,
            ),
          );
        }
      }

      const cleanupResults =
        await Promise.all(
          cleanupPromises,
        );

      invalidTokensRemoved +=
        cleanupResults.filter(
          (result) => result === true,
        ).length;
    } catch (error) {
      console.error(
        `FCM send failed for user ${cleanUserId}:`,
        error.message,
      );

      failed += tokens.length;
    }
  }

  return {
    userId: cleanUserId,
    notificationCreated: true,
    notificationId,
    sent,
    failed,
    invalidTokensRemoved,
    totalDevices: devices.length,
  };
}

// ============================================================
// SEND NOTIFICATION TO ONE MEMBER
// ============================================================

async function sendNotificationToMember({
  userId,
  title,
  body,
  type = "general",
  route = null,
  imageObjectKey = null,
  data = {},
}) {
  return sendToUserDevices({
    userId,
    title,
    body,
    type,
    route,
    imageObjectKey,
    data,
  });
}

// ============================================================
// SEND NOTIFICATION TO ALL MEMBERS
// ============================================================

async function sendNotificationToAllMembers({
  title,
  body,
  type = "general",
  route = null,
  imageObjectKey = null,
  data = {},
}) {
  const db = getDb();

  const membersSnapshot =
    await db
      .collection("users")
      .where(
        "role",
        "==",
        "member",
      )
      .where(
        "accountStatus",
        "==",
        "active",
      )
      .get();

  let membersProcessed = 0;
  let membersWithDevices = 0;
  let sent = 0;
  let failed = 0;
  let invalidTokensRemoved = 0;
  let notificationsCreated = 0;

  // ----------------------------------------------------------
  // PROCESS MEMBERS IN GROUPS OF 10
  // ----------------------------------------------------------

  const CONCURRENCY = 10;

  for (
    let start = 0;
    start < membersSnapshot.docs.length;
    start += CONCURRENCY
  ) {
    const batch =
      membersSnapshot.docs.slice(
        start,
        start + CONCURRENCY,
      );

    const results =
      await Promise.all(
        batch.map(
          async (memberDoc) => {
            try {
              const result =
                await sendToUserDevices({
                  userId:
                    memberDoc.id,
                  title,
                  body,
                  type,
                  route,
                  imageObjectKey,
                  data,
                });

              return result;
            } catch (error) {
              console.error(
                `Notification failed for member ${memberDoc.id}:`,
                error.message,
              );

              return {
                userId:
                  memberDoc.id,
                notificationCreated:
                  false,
                notificationId: null,
                sent: 0,
                failed: 1,
                invalidTokensRemoved: 0,
                totalDevices: 0,
              };
            }
          },
        ),
      );

    for (const result of results) {
      membersProcessed++;

      if (result.totalDevices > 0) {
        membersWithDevices++;
      }

      if (
        result.notificationCreated
      ) {
        notificationsCreated++;
      }

      sent += result.sent;
      failed += result.failed;

      invalidTokensRemoved +=
        result.invalidTokensRemoved;
    }
  }

  return {
    totalMembers:
      membersSnapshot.size,

    membersProcessed,

    membersWithDevices,

    notificationsCreated,

    sent,

    failed,

    invalidTokensRemoved,
  };
}

// ============================================================
// DELETE USER NOTIFICATION
// ============================================================

async function deleteUserNotification({
  userId,
  notificationId,
}) {
  const db = getDb();

  const cleanUserId =
    normalizeString(userId, 200);

  const cleanNotificationId =
    normalizeString(
      notificationId,
      200,
    );

  if (!cleanUserId) {
    throw new Error(
      "User ID is required.",
    );
  }

  if (!cleanNotificationId) {
    throw new Error(
      "Notification ID is required.",
    );
  }

  await db
    .collection("users")
    .doc(cleanUserId)
    .collection("notifications")
    .doc(cleanNotificationId)
    .delete();

  return true;
}

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  sendNotificationToMember,
  sendNotificationToAllMembers,
  deleteUserNotification,
};