require("dotenv").config();

const express = require("express");
const cors = require("cors");

const {
  initializeApp,
  cert,
} = require("firebase-admin/app");

const {
  getAuth,
} = require("firebase-admin/auth");

const {
  getFirestore,
} = require("firebase-admin/firestore");

const {
  S3Client,
  HeadBucketCommand,
  PutObjectCommand,
  GetObjectCommand,
} = require("@aws-sdk/client-s3");

const {
  getSignedUrl,
} = require("@aws-sdk/s3-request-presigner");

// ============================================================
// FIREBASE ADMIN
// ============================================================

const serviceAccount =
  require("./firebase-service-account.json");

initializeApp({
  credential: cert(serviceAccount),
  projectId: process.env.FIREBASE_PROJECT_ID,
});

const auth = getAuth();
const db = getFirestore();

// ============================================================
// EXPRESS
// ============================================================

const app = express();

const PORT = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// ============================================================
// BACKBLAZE B2 CONFIGURATION
// ============================================================

const B2_BUCKET =
  process.env.B2_BUCKET;

const B2_REGION =
  process.env.B2_REGION;

const B2_ENDPOINT =
  process.env.B2_ENDPOINT;

// ============================================================
// VALIDATE B2 CONFIGURATION
// ============================================================

if (!B2_BUCKET) {
  console.error(
    "❌ B2_BUCKET is not configured.",
  );
}

if (!B2_REGION) {
  console.error(
    "❌ B2_REGION is not configured.",
  );
}

if (!B2_ENDPOINT) {
  console.error(
    "❌ B2_ENDPOINT is not configured.",
  );
}

if (!process.env.B2_KEY_ID) {
  console.error(
    "❌ B2_KEY_ID is not configured.",
  );
}

if (!process.env.B2_APPLICATION_KEY) {
  console.error(
    "❌ B2_APPLICATION_KEY is not configured.",
  );
}

// ============================================================
// BACKBLAZE S3 CLIENT
// ============================================================

const s3 = new S3Client({
  endpoint: B2_ENDPOINT,
  region: B2_REGION,
  credentials: {
    accessKeyId:
      process.env.B2_KEY_ID,

    secretAccessKey:
      process.env.B2_APPLICATION_KEY,
  },
});

// ============================================================
// OBJECT KEY SECURITY HELPERS
// ============================================================

function isSafeSermonObjectKey(objectKey) {
  if (
    !objectKey ||
    typeof objectKey !== "string"
  ) {
    return false;
  }

  if (objectKey.includes("..")) {
    return false;
  }

  if (objectKey.startsWith("/")) {
    return false;
  }

  return objectKey.startsWith("sermons/");
}

function isSafeEventObjectKey(objectKey) {
  if (
    !objectKey ||
    typeof objectKey !== "string"
  ) {
    return false;
  }

  if (objectKey.includes("..")) {
    return false;
  }

  if (objectKey.startsWith("/")) {
    return false;
  }

  return objectKey.startsWith(
    "events/flyers/",
  );
}

function isSafeBookObjectKey(objectKey) {
  if (
    !objectKey ||
    typeof objectKey !== "string"
  ) {
    return false;
  }

  if (objectKey.includes("..")) {
    return false;
  }

  if (objectKey.startsWith("/")) {
    return false;
  }

  return objectKey.startsWith(
    "books/ebooks/",
  );
}

function isSafeBookCoverObjectKey(objectKey) {
  if (
    !objectKey ||
    typeof objectKey !== "string"
  ) {
    return false;
  }

  if (objectKey.includes("..")) {
    return false;
  }

  if (objectKey.startsWith("/")) {
    return false;
  }

  return objectKey.startsWith(
    "books/covers/",
  );
}

// ============================================================
// FIREBASE AUTHENTICATION MIDDLEWARE
// ============================================================

async function authenticateFirebase(
  req,
  res,
  next,
) {
  try {
    const authorization =
      req.headers.authorization;

    if (!authorization) {
      return res.status(401).json({
        success: false,
        message:
          "Authorization token is required.",
      });
    }

    if (
      !authorization.startsWith(
        "Bearer ",
      )
    ) {
      return res.status(401).json({
        success: false,
        message:
          "Invalid authorization format.",
      });
    }

    const idToken =
      authorization
        .substring(7)
        .trim();

    if (!idToken) {
      return res.status(401).json({
        success: false,
        message:
          "Firebase ID token is missing.",
      });
    }

    const decodedToken =
      await auth.verifyIdToken(
        idToken,
      );

    req.user = decodedToken;

    next();
  } catch (error) {
    console.error(
      "Firebase authentication failed:",
      error.message,
    );

    return res.status(401).json({
      success: false,
      message:
        "Invalid or expired authentication token.",
    });
  }
}

// ============================================================
// ADMIN AUTHORIZATION MIDDLEWARE
// ============================================================

async function requireAdmin(
  req,
  res,
  next,
) {
  try {
    const uid =
      req.user.uid;

    const userSnapshot =
      await db
        .collection("users")
        .doc(uid)
        .get();

    if (!userSnapshot.exists) {
      return res.status(403).json({
        success: false,
        message:
          "User profile not found.",
      });
    }

    const userData =
      userSnapshot.data() || {};

    if (
      userData.role !== "admin"
    ) {
      return res.status(403).json({
        success: false,
        message:
          "Administrator access is required.",
      });
    }

    req.adminUser = {
      uid: uid,
      ...userData,
    };

    next();
  } catch (error) {
    console.error(
      "Admin authorization failed:",
      error.message,
    );

    return res.status(500).json({
      success: false,
      message:
        "Unable to verify administrator access.",
    });
  }
}

// ============================================================
// ROOT HEALTH CHECK
// ============================================================

app.get(
  "/",
  (req, res) => {
    return res.json({
      success: true,
      service:
        "RHIC B2 Media Backend",
      status: "online",
    });
  },
);

// ============================================================
// B2 HEALTH CHECK
// ============================================================

app.get(
  "/health/b2",
  async (req, res) => {
    try {
      await s3.send(
        new HeadBucketCommand({
          Bucket: B2_BUCKET,
        }),
      );

      return res.json({
        success: true,
        message:
          "Backblaze B2 connection is working.",
        bucket: B2_BUCKET,
        region: B2_REGION,
      });
    } catch (error) {
      console.error(
        "B2 health check failed:",
        error.message,
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to connect to Backblaze B2.",
      });
    }
  },
);

// ============================================================
// CREATE SECURE UPLOAD URL
// ============================================================
//
// resourceType:
//
// sermon:
//   video -> sermons/video/...
//   audio -> sermons/audio/...
//   ebook -> sermons/ebook/...
//   image -> sermons/image/...
//
// book:
//   image -> books/covers/...
//   ebook -> books/ebooks/...
//
// event:
//   image -> events/flyers/...
//
// ============================================================

app.post(
  "/upload-url",
  authenticateFirebase,
  requireAdmin,
  async (req, res) => {
    try {
      const {
        fileName,
        contentType,
        mediaType,
        resourceType = "sermon",
      } = req.body;

      // ------------------------------------------------------
      // FILE NAME
      // ------------------------------------------------------

      if (
        typeof fileName !== "string" ||
        fileName.trim().length === 0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "A file name is required.",
        });
      }

      // ------------------------------------------------------
      // CONTENT TYPE
      // ------------------------------------------------------

      if (
        typeof contentType !== "string" ||
        contentType.trim().length === 0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "A content type is required.",
        });
      }

      // ------------------------------------------------------
      // MEDIA TYPE
      // ------------------------------------------------------

      const allowedMediaTypes = [
        "video",
        "audio",
        "ebook",
        "image",
      ];

      if (
        !allowedMediaTypes.includes(
          mediaType,
        )
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Invalid media type.",
        });
      }

      // ------------------------------------------------------
      // RESOURCE TYPE
      // ------------------------------------------------------

      const allowedResourceTypes = [
        "sermon",
        "book",
        "event",
      ];

      if (
        !allowedResourceTypes.includes(
          resourceType,
        )
      ) {
        return res.status(400).json({
          success: false,
          message:
            "Invalid resource type.",
        });
      }

      // ------------------------------------------------------
      // NORMALIZE CONTENT TYPE
      // ------------------------------------------------------

      const normalizedContentType =
        contentType
          .trim()
          .toLowerCase();

      // ======================================================
      // BOOK UPLOAD VALIDATION
      // ======================================================

      if (resourceType === "book") {
        // ----------------------------------------------------
        // BOOK EBOOK
        // ----------------------------------------------------

        if (mediaType === "ebook") {
          if (
            normalizedContentType !==
            "application/pdf"
          ) {
            return res.status(400).json({
              success: false,
              message:
                "Book ebooks must be PDF files.",
            });
          }
        }

        // ----------------------------------------------------
        // BOOK COVER
        // ----------------------------------------------------

        else if (
          mediaType === "image"
        ) {
          const allowedBookCoverTypes = [
            "image/jpeg",
            "image/png",
            "image/webp",
          ];

          if (
            !allowedBookCoverTypes.includes(
              normalizedContentType,
            )
          ) {
            return res.status(400).json({
              success: false,
              message:
                "Book covers must be JPG, PNG, or WEBP images.",
            });
          }
        }

        // ----------------------------------------------------
        // INVALID BOOK MEDIA
        // ----------------------------------------------------

        else {
          return res.status(400).json({
            success: false,
            message:
              "Books can only have cover images or ebook PDFs.",
          });
        }
      }

      // ======================================================
      // EVENT UPLOAD VALIDATION
      // ======================================================

      if (resourceType === "event") {
        // Events currently support flyer images only.

        if (mediaType !== "image") {
          return res.status(400).json({
            success: false,
            message:
              "Events can only have flyer images.",
          });
        }

        const allowedEventImageTypes = [
          "image/jpeg",
          "image/png",
          "image/webp",
        ];

        if (
          !allowedEventImageTypes.includes(
            normalizedContentType,
          )
        ) {
          return res.status(400).json({
            success: false,
            message:
              "Event flyers must be JPG, PNG, or WEBP images.",
          });
        }
      }

      // ======================================================
      // SERMON UPLOAD VALIDATION
      // ======================================================

      if (resourceType === "sermon") {
        const allowedSermonContentTypes = {
          video: [
            "video/mp4",
            "video/webm",
            "video/quicktime",
          ],

          audio: [
            "audio/mpeg",
            "audio/mp3",
            "audio/wav",
            "audio/x-wav",
            "audio/mp4",
            "audio/aac",
            "audio/ogg",
          ],

          ebook: [
            "application/pdf",
          ],

          image: [
            "image/jpeg",
            "image/png",
            "image/webp",
          ],
        };

        if (
          !allowedSermonContentTypes[
            mediaType
          ].includes(
            normalizedContentType,
          )
        ) {
          return res.status(400).json({
            success: false,
            message:
              `File type "${contentType}" is not allowed for ${mediaType}.`,
          });
        }
      }

      // ------------------------------------------------------
      // SANITIZE FILE NAME
      // ------------------------------------------------------

      const safeFileName =
        fileName
          .trim()
          .replace(
            /[^a-zA-Z0-9._-]/g,
            "_",
          )
          .replace(
            /_+/g,
            "_",
          );

      // ------------------------------------------------------
      // UNIQUE FILE NAME
      // ------------------------------------------------------

      const timestamp =
        Date.now();

      const randomPart =
        Math.random()
          .toString(36)
          .substring(
            2,
            10,
          );

      // ======================================================
      // CREATE OBJECT KEY
      // ======================================================

      let objectKey;

      // ------------------------------------------------------
      // EVENT FLYER
      // ------------------------------------------------------

      if (
        resourceType === "event" &&
        mediaType === "image"
      ) {
        objectKey =
          `events/flyers/${timestamp}-${randomPart}-${safeFileName}`;
      }

      // ------------------------------------------------------
      // BOOK COVER
      // ------------------------------------------------------

      else if (
        resourceType === "book" &&
        mediaType === "image"
      ) {
        objectKey =
          `books/covers/${timestamp}-${randomPart}-${safeFileName}`;
      }

      // ------------------------------------------------------
      // BOOK EBOOK
      // ------------------------------------------------------

      else if (
        resourceType === "book" &&
        mediaType === "ebook"
      ) {
        objectKey =
          `books/ebooks/${timestamp}-${randomPart}-${safeFileName}`;
      }

      // ------------------------------------------------------
      // SERMON MEDIA
      // ------------------------------------------------------

      else {
        objectKey =
          `sermons/${mediaType}/${timestamp}-${randomPart}-${safeFileName}`;
      }

      // ------------------------------------------------------
      // CREATE PUT COMMAND
      // ------------------------------------------------------

      const command =
        new PutObjectCommand({
          Bucket: B2_BUCKET,
          Key: objectKey,
          ContentType:
            normalizedContentType,
        });

      // ------------------------------------------------------
      // CREATE SIGNED UPLOAD URL
      // ------------------------------------------------------

      const uploadUrl =
        await getSignedUrl(
          s3,
          command,
          {
            expiresIn: 900,
          },
        );

      return res.json({
        success: true,
        uploadUrl:
          uploadUrl,
        objectKey:
          objectKey,
        bucket:
          B2_BUCKET,
        region:
          B2_REGION,
        expiresIn:
          900,
        contentType:
          normalizedContentType,
        mediaType:
          mediaType,
        resourceType:
          resourceType,
      });
    } catch (error) {
      console.error(
        "Failed to create upload URL:",
        error.message,
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to create upload URL.",
      });
    }
  },
);

// ============================================================
// SECURE SERMON DOWNLOAD URL
// ============================================================
//
// Used only for sermon media.
//
// ============================================================

app.post(
  "/download-url",
  authenticateFirebase,
  async (req, res) => {
    try {
      const {
        objectKey,
      } = req.body;

      if (
        typeof objectKey !== "string" ||
        objectKey.trim().length === 0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "A B2 object key is required.",
        });
      }

      const normalizedObjectKey =
        objectKey.trim();

      if (
        !isSafeSermonObjectKey(
          normalizedObjectKey,
        )
      ) {
        return res.status(403).json({
          success: false,
          message:
            "Access to this object is not allowed.",
        });
      }

      const command =
        new GetObjectCommand({
          Bucket: B2_BUCKET,
          Key: normalizedObjectKey,
        });

      const downloadUrl =
        await getSignedUrl(
          s3,
          command,
          {
            expiresIn: 300,
          },
        );

      return res.json({
        success: true,
        downloadUrl:
          downloadUrl,
        expiresIn:
          300,
      });
    } catch (error) {
      console.error(
        "Failed to create sermon download URL:",
        error.message,
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to create download URL.",
      });
    }
  },
);

// ============================================================
// SECURE EVENT FLYER DOWNLOAD URL
// ============================================================
//
// Used only for event flyers.
//
// The client sends:
// {
//   objectKey: "events/flyers/..."
// }
//
// ============================================================

app.post(
  "/event-download-url",
  authenticateFirebase,
  async (req, res) => {
    try {
      const {
        objectKey,
      } = req.body;

      if (
        typeof objectKey !== "string" ||
        objectKey.trim().length === 0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "A B2 event object key is required.",
        });
      }

      const normalizedObjectKey =
        objectKey.trim();

      // ------------------------------------------------------
      // VERIFY EVENT OBJECT KEY
      // ------------------------------------------------------

      if (
        !isSafeEventObjectKey(
          normalizedObjectKey,
        )
      ) {
        return res.status(403).json({
          success: false,
          message:
            "Access to this event object is not allowed.",
        });
      }

      // ------------------------------------------------------
      // CREATE TEMPORARY EVENT URL
      // ------------------------------------------------------

      const command =
        new GetObjectCommand({
          Bucket: B2_BUCKET,
          Key: normalizedObjectKey,
        });

      const downloadUrl =
        await getSignedUrl(
          s3,
          command,
          {
            expiresIn: 300,
          },
        );

      return res.json({
        success: true,
        downloadUrl:
          downloadUrl,
        expiresIn:
          300,
      });
    } catch (error) {
      console.error(
        "Failed to create event download URL:",
        error.message,
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to create event download URL.",
      });
    }
  },
);

// ============================================================
// SECURE BOOK COVER URL
// ============================================================
//
// The client sends the bookId only.
//
// The server loads coverObjectKey from Firestore.
//
// ============================================================

app.post(
  "/book-cover-url",
  authenticateFirebase,
  async (req, res) => {
    try {
      const {
        bookId,
      } = req.body;

      if (
        typeof bookId !== "string" ||
        bookId.trim().length === 0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "A book ID is required.",
        });
      }

      const normalizedBookId =
        bookId.trim();

      // ------------------------------------------------------
      // LOAD BOOK
      // ------------------------------------------------------

      const bookSnapshot =
        await db
          .collection("books")
          .doc(normalizedBookId)
          .get();

      if (!bookSnapshot.exists) {
        return res.status(404).json({
          success: false,
          message:
            "Book not found.",
        });
      }

      const bookData =
        bookSnapshot.data() || {};

      // ------------------------------------------------------
      // GET COVER OBJECT KEY
      // ------------------------------------------------------

      const coverObjectKey =
        typeof bookData.coverObjectKey === "string"
          ? bookData.coverObjectKey.trim()
          : "";

      if (!coverObjectKey) {
        return res.status(404).json({
          success: false,
          message:
            "This book does not have a cover image.",
        });
      }

      // ------------------------------------------------------
      // VERIFY COVER OBJECT KEY
      // ------------------------------------------------------

      if (
        !isSafeBookCoverObjectKey(
          coverObjectKey,
        )
      ) {
        return res.status(403).json({
          success: false,
          message:
            "This cover image is not configured correctly.",
        });
      }

      // ------------------------------------------------------
      // CREATE TEMPORARY COVER URL
      // ------------------------------------------------------

      const command =
        new GetObjectCommand({
          Bucket: B2_BUCKET,
          Key: coverObjectKey,
        });

      const coverUrl =
        await getSignedUrl(
          s3,
          command,
          {
            expiresIn: 900,
          },
        );

      return res.json({
        success: true,
        coverUrl:
          coverUrl,
        expiresIn:
          900,
      });
    } catch (error) {
      console.error(
        "Failed to create book cover URL:",
        error.message,
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to create book cover URL.",
      });
    }
  },
);

// ============================================================
// SECURE PURCHASED BOOK DOWNLOAD URL
// ============================================================
//
// IMPORTANT:
//
// Client sends ONLY:
// {
//   bookId: "..."
// }
//
// Server:
// 1. Authenticates user.
// 2. Loads book.
// 3. Gets ebookObjectKey from Firestore.
// 4. Verifies approved purchase.
// 5. Creates temporary B2 URL.
//
// ============================================================

app.post(
  "/book-download-url",
  authenticateFirebase,
  async (req, res) => {
    try {
      const {
        bookId,
      } = req.body;

      // ------------------------------------------------------
      // BOOK ID
      // ------------------------------------------------------

      if (
        typeof bookId !== "string" ||
        bookId.trim().length === 0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "A book ID is required.",
        });
      }

      const normalizedBookId =
        bookId.trim();

      // ------------------------------------------------------
      // LOAD BOOK
      // ------------------------------------------------------

      const bookSnapshot =
        await db
          .collection("books")
          .doc(normalizedBookId)
          .get();

      if (!bookSnapshot.exists) {
        return res.status(404).json({
          success: false,
          message:
            "Book not found.",
        });
      }

      const bookData =
        bookSnapshot.data() || {};

      // ------------------------------------------------------
      // GET PRIVATE EBOOK OBJECT KEY
      // ------------------------------------------------------

      const ebookObjectKey =
        typeof bookData.ebookObjectKey === "string"
          ? bookData.ebookObjectKey.trim()
          : "";

      if (!ebookObjectKey) {
        return res.status(404).json({
          success: false,
          message:
            "This book does not have an ebook file.",
        });
      }

      // ------------------------------------------------------
      // VERIFY OBJECT KEY
      // ------------------------------------------------------

      if (
        !isSafeBookObjectKey(
          ebookObjectKey,
        )
      ) {
        console.error(
          `Invalid ebook object key for book ${normalizedBookId}:`,
          ebookObjectKey,
        );

        return res.status(403).json({
          success: false,
          message:
            "This ebook file is not configured correctly.",
        });
      }

      // ------------------------------------------------------
      // FIND APPROVED PURCHASE
      // ------------------------------------------------------

      const ordersSnapshot =
        await db
          .collection("book_orders")
          .where(
            "userId",
            "==",
            req.user.uid,
          )
          .where(
            "status",
            "==",
            "approved",
          )
          .get();

      let hasApprovedPurchase =
        false;

      for (
        const orderDoc of
          ordersSnapshot.docs
      ) {
        const orderData =
          orderDoc.data() || {};

        const items =
          Array.isArray(
            orderData.items,
          )
            ? orderData.items
            : [];

        const purchasedBook =
          items.some(
            (item) =>
              item &&
              item.bookId?.toString() ===
                normalizedBookId,
          );

        if (
          purchasedBook
        ) {
          hasApprovedPurchase =
            true;
          break;
        }
      }

      // ------------------------------------------------------
      // DENY UNPAID ACCESS
      // ------------------------------------------------------

      if (
        !hasApprovedPurchase
      ) {
        return res.status(403).json({
          success: false,
          message:
            "You do not have an approved purchase for this ebook.",
        });
      }

      // ------------------------------------------------------
      // CREATE TEMPORARY EBOOK URL
      // ------------------------------------------------------

      const command =
        new GetObjectCommand({
          Bucket: B2_BUCKET,
          Key: ebookObjectKey,
        });

      const downloadUrl =
        await getSignedUrl(
          s3,
          command,
          {
            expiresIn:
              300,
          },
        );

      return res.json({
        success: true,
        downloadUrl:
          downloadUrl,
        expiresIn:
          300,
      });
    } catch (error) {
      console.error(
        "Failed to create book download URL:",
        error.message,
      );

      return res.status(500).json({
        success: false,
        message:
          "Unable to create book download URL.",
      });
    }
  },
);

// ============================================================
// 404 HANDLER
// ============================================================

app.use(
  (req, res) => {
    return res.status(404).json({
      success: false,
      message:
        "Endpoint not found.",
    });
  },
);

// ============================================================
// GLOBAL ERROR HANDLER
// ============================================================

app.use(
  (
    error,
    req,
    res,
    next,
  ) => {
    console.error(
      "Unhandled server error:",
      error,
    );

    return res.status(500).json({
      success: false,
      message:
        "An unexpected server error occurred.",
    });
  },
);

// ============================================================
// START SERVER
// ============================================================

app.listen(
  PORT,
  () => {
    console.log("");

    console.log(
      "============================================",
    );

    console.log(
      " RHIC B2 MEDIA BACKEND",
    );

    console.log(
      "============================================",
    );

    console.log(
      ` Server: http://localhost:${PORT}`,
    );

    console.log(
      ` Bucket: ${B2_BUCKET}`,
    );

    console.log(
      ` Region: ${B2_REGION}`,
    );

    console.log(
      " Firebase authentication: ENABLED",
    );

    console.log(
      " Admin authorization: ENABLED",
    );

    console.log(
      " Upload URLs: ENABLED",
    );

    console.log(
      " Sermon download access: ENABLED",
    );

    console.log(
      " Event flyer access: ENABLED",
    );

    console.log(
      " Book cover access: ENABLED",
    );

    console.log(
      " Secure purchased ebook access: ENABLED",
    );

    console.log(
      "============================================",
    );

    console.log("");
  },
);