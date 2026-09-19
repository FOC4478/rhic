const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");

const {
  sendNotificationToMember,
} = require("../services/notificationService");

// ============================================================
// FIRESTORE
// ============================================================

function getDb() {
  return getFirestore();
}

// ============================================================
// APPROVE BOOK ORDER
// ============================================================

const approveOrder = async (req, res) => {
  try {
    const adminId = req.user?.uid;

    if (!adminId) {
      return res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
    }

    const { orderId, adminNote } = req.body;

    if (!orderId || typeof orderId !== "string") {
      return res.status(400).json({
        success: false,
        message: "Order ID is required.",
      });
    }

    const db = getDb();

    const orderRef = db
      .collection("book_orders")
      .doc(orderId.trim());

    const orderSnap = await orderRef.get();

    if (!orderSnap.exists) {
      return res.status(404).json({
        success: false,
        message: "Order not found.",
      });
    }

    const order = orderSnap.data();

    // Prevent approving an already processed order.
    if (order.status !== "pending") {
      return res.status(409).json({
        success: false,
        message:
            "This order has already been processed.",
        currentStatus: order.status,
      });
    }

    const cleanNote =
        typeof adminNote === "string"
            ? adminNote.trim()
            : "";

    // ========================================================
    // APPROVE ORDER
    // ========================================================

    await orderRef.update({
      status: "approved",
      verifiedBy: adminId,
      verifiedAt:
          FieldValue.serverTimestamp(),
      adminNote: cleanNote,
    });

    // ========================================================
    // SEND PAYMENT APPROVED NOTIFICATION
    // ========================================================

    let notificationResult = null;

    if (order.userId) {
      try {
        notificationResult =
            await sendNotificationToMember({
          userId: order.userId,
          title: "Payment Approved",
          body:
              "Your bookstore payment has been approved. Your purchased book is now available.",
          type: "payment",
          route: "/library",
          data: {
            orderId: orderId.trim(),
          },
        });
      } catch (notificationError) {
        console.error(
          "Payment approved, but notification failed:",
          notificationError,
        );

        notificationResult = {
          success: false,
          error: notificationError.message,
        };
      }
    }

    return res.status(200).json({
      success: true,
      message: "Order approved successfully.",
      orderId: orderId.trim(),
      notification: notificationResult,
    });
  } catch (error) {
    console.error(
      "Approve order error:",
      error,
    );

    return res.status(500).json({
      success: false,
      message: "Unable to approve order.",
    });
  }
};

// ============================================================
// REJECT BOOK ORDER
// ============================================================

const rejectOrder = async (req, res) => {
  try {
    const adminId = req.user?.uid;

    if (!adminId) {
      return res.status(401).json({
        success: false,
        message: "Authentication required.",
      });
    }

    const { orderId, adminNote } = req.body;

    if (!orderId || typeof orderId !== "string") {
      return res.status(400).json({
        success: false,
        message: "Order ID is required.",
      });
    }

    const db = getDb();

    const orderRef = db
      .collection("book_orders")
      .doc(orderId.trim());

    const orderSnap = await orderRef.get();

    if (!orderSnap.exists) {
      return res.status(404).json({
        success: false,
        message: "Order not found.",
      });
    }

    const order = orderSnap.data();

    if (order.status !== "pending") {
      return res.status(409).json({
        success: false,
        message:
            "This order has already been processed.",
        currentStatus: order.status,
      });
    }

    const cleanNote =
        typeof adminNote === "string"
            ? adminNote.trim()
            : "";

    // ========================================================
    // REJECT ORDER
    // ========================================================

    await orderRef.update({
      status: "rejected",
      verifiedBy: adminId,
      verifiedAt:
          FieldValue.serverTimestamp(),
      adminNote: cleanNote,
    });

    return res.status(200).json({
      success: true,
      message: "Order rejected successfully.",
      orderId: orderId.trim(),
    });
  } catch (error) {
    console.error(
      "Reject order error:",
      error,
    );

    return res.status(500).json({
      success: false,
      message: "Unable to reject order.",
    });
  }
};

// ============================================================
// EXPORTS
// ============================================================

module.exports = {
  approveOrder,
  rejectOrder,
};