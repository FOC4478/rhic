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

// Allow requests from Flutter Web and other configured clients.
app.use(cors());

// Parse JSON request bodies.
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

    // --------------------------------------------------------
    // AUTHORIZATION HEADER REQUIRED
    // --------------------------------------------------------

    if (!authorization) {
      return res.status(401).json({
        success: false,
        message:
          "Authorization token is required.",
      });
    }

    // --------------------------------------------------------
    // CHECK BEARER FORMAT
    // --------------------------------------------------------

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

    // --------------------------------------------------------
    // EXTRACT FIREBASE ID TOKEN
    // --------------------------------------------------------

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

    // --------------------------------------------------------
    // VERIFY FIREBASE TOKEN
    // --------------------------------------------------------

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

    // --------------------------------------------------------
    // LOAD USER PROFILE
    // --------------------------------------------------------

    const userSnapshot =
      await db
        .collection("users")
        .doc(uid)
        .get();

    // --------------------------------------------------------
    // USER PROFILE NOT FOUND
    // --------------------------------------------------------

    if (!userSnapshot.exists) {
      return res.status(403).json({
        success: false,
        message:
          "User profile not found.",
      });
    }

    const userData =
      userSnapshot.data() || {};

    // --------------------------------------------------------
    // CHECK ADMIN ROLE
    // --------------------------------------------------------

    if (
      userData.role !== "admin"
    ) {
      return res.status(403).json({
        success: false,
        message:
          "Administrator access is required.",
      });
    }

    // --------------------------------------------------------
    // STORE ADMIN INFORMATION
    // --------------------------------------------------------

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
    res.json({
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
      } = req.body;

      // ------------------------------------------------------
      // VALIDATE FILE NAME
      // ------------------------------------------------------

      if (
        typeof fileName !==
          "string" ||
        fileName.trim().length === 0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "A file name is required.",
        });
      }

      // ------------------------------------------------------
      // VALIDATE CONTENT TYPE
      // ------------------------------------------------------

      if (
        typeof contentType !==
          "string" ||
        contentType.trim().length === 0
      ) {
        return res.status(400).json({
          success: false,
          message:
            "A content type is required.",
        });
      }

      // ------------------------------------------------------
      // VALIDATE MEDIA TYPE
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
      // ALLOWED CONTENT TYPES
      // ------------------------------------------------------

      const allowedContentTypes = {
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

      // ------------------------------------------------------
      // NORMALIZE CONTENT TYPE
      // ------------------------------------------------------

      const normalizedContentType =
        contentType
          .trim()
          .toLowerCase();

      // ------------------------------------------------------
      // CHECK CONTENT TYPE
      // ------------------------------------------------------

      if (
        !allowedContentTypes[
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
      // CREATE UNIQUE FILE NAME
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

      // ------------------------------------------------------
      // CREATE B2 OBJECT KEY
      // ------------------------------------------------------

      const objectKey =
        `sermons/${mediaType}/${timestamp}-${randomPart}-${safeFileName}`;

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

      // ------------------------------------------------------
      // RETURN UPLOAD INFORMATION
      // ------------------------------------------------------

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
// CREATE SECURE DOWNLOAD URL
// ============================================================

app.post(
  "/download-url",
  authenticateFirebase,
  async (req, res) => {
    try {
      const {
        objectKey,
      } = req.body;

      // ------------------------------------------------------
      // VALIDATE OBJECT KEY
      // ------------------------------------------------------

      if (
        typeof objectKey !==
          "string" ||
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

      // ------------------------------------------------------
      // SECURITY CHECK
      // ------------------------------------------------------
      // All RHIC sermon media must live
      // inside the sermons/ directory.

      if (
        !normalizedObjectKey.startsWith(
          "sermons/",
        )
      ) {
        return res.status(403).json({
          success: false,
          message:
            "Access to this object is not allowed.",
        });
      }

      // ------------------------------------------------------
      // PATH TRAVERSAL PROTECTION
      // ------------------------------------------------------

      if (
        normalizedObjectKey.includes(
          "..",
        )
      ) {
        return res.status(403).json({
          success: false,
          message:
            "Invalid object key.",
        });
      }

      // ------------------------------------------------------
      // CREATE GET COMMAND
      // ------------------------------------------------------

      const command =
        new GetObjectCommand({
          Bucket: B2_BUCKET,
          Key: normalizedObjectKey,
        });

      // ------------------------------------------------------
      // CREATE TEMPORARY SIGNED DOWNLOAD URL
      // ------------------------------------------------------

      const downloadUrl =
        await getSignedUrl(
          s3,
          command,
          {
            expiresIn: 300,
          },
        );

      // ------------------------------------------------------
      // RETURN DOWNLOAD URL
      // ------------------------------------------------------

      return res.json({
        success: true,

        downloadUrl:
          downloadUrl,

        expiresIn:
          300,
      });
    } catch (error) {
      console.error(
        "Failed to create download URL:",
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
      " Download URLs: ENABLED",
    );

    console.log(
      "============================================",
    );

    console.log("");
  },
);