const {setGlobalOptions} = require("firebase-functions");
const {
  onCall,
  HttpsError,
} = require("firebase-functions/https");
const {
  defineString,
} = require("firebase-functions/params");
const logger = require("firebase-functions/logger");
const axios = require("axios");

setGlobalOptions({
  maxInstances: 10,
});

// ============================================================
// YOUTUBE API CONFIGURATION
// ============================================================

const youtubeApiKey = defineString("YOUTUBE_API_KEY");

// ============================================================
// YOUTUBE LIVE STATUS
// ============================================================

exports.checkYouTubeLive = onCall(
    {
      maxInstances: 10,
    },
    async (request) => {
    // ----------------------------------------------------------
    // VALIDATE REQUEST
    // ----------------------------------------------------------

      const youtubeVideoId =
      request.data &&
      request.data.youtubeVideoId;

      if (
        typeof youtubeVideoId !== "string" ||
      youtubeVideoId.trim().length === 0
      ) {
        throw new HttpsError(
            "invalid-argument",
            "A valid YouTube video ID is required.",
        );
      }

      // ----------------------------------------------------------
      // YOUTUBE API KEY
      // ----------------------------------------------------------

      const apiKey = youtubeApiKey.value();

      if (!apiKey) {
        logger.error(
            "YOUTUBE_API_KEY is not configured.",
        );

        throw new HttpsError(
            "failed-precondition",
            "YouTube API is not configured.",
        );
      }

      // ----------------------------------------------------------
      // YOUTUBE API REQUEST
      // ----------------------------------------------------------

      try {
        const response = await axios.get(
            "https://www.googleapis.com/youtube/v3/videos",
            {
              params: {
                part: "snippet,liveStreamingDetails",
                id: youtubeVideoId.trim(),
                key: apiKey,
              },
            },
        );

        const items =
        response.data &&
        response.data.items ?
          response.data.items :
          [];

        // --------------------------------------------------------
        // BROADCAST NOT FOUND
        // --------------------------------------------------------

        if (items.length === 0) {
          return {
            exists: false,
            status: "not_found",
            youtubeVideoId:
            youtubeVideoId.trim(),
          };
        }

        const video = items[0];

        const liveDetails =
        video.liveStreamingDetails ?
          video.liveStreamingDetails :
          {};

        // --------------------------------------------------------
        // LIVE TIMES
        // --------------------------------------------------------

        const scheduledStartTime =
        liveDetails.scheduledStartTime ?
          liveDetails.scheduledStartTime :
          null;

        const scheduledEndTime =
        liveDetails.scheduledEndTime ?
          liveDetails.scheduledEndTime :
          null;

        const actualStartTime =
        liveDetails.actualStartTime ?
          liveDetails.actualStartTime :
          null;

        const actualEndTime =
        liveDetails.actualEndTime ?
          liveDetails.actualEndTime :
          null;

        // --------------------------------------------------------
        // DETERMINE STATUS
        // --------------------------------------------------------

        let status = "upcoming";

        if (
          actualStartTime &&
        !actualEndTime
        ) {
          status = "live";
        }

        if (actualEndTime) {
          status = "complete";
        }

        // --------------------------------------------------------
        // VIDEO TITLE
        // --------------------------------------------------------

        const title =
        video.snippet &&
        video.snippet.title ?
          video.snippet.title :
          "";

        // --------------------------------------------------------
        // THUMBNAIL
        // --------------------------------------------------------

        let thumbnailUrl = "";

        if (
          video.snippet &&
        video.snippet.thumbnails
        ) {
          const thumbnails =
          video.snippet.thumbnails;

          if (
            thumbnails.high &&
          thumbnails.high.url
          ) {
            thumbnailUrl =
            thumbnails.high.url;
          } else if (
            thumbnails.medium &&
          thumbnails.medium.url
          ) {
            thumbnailUrl =
            thumbnails.medium.url;
          } else if (
            thumbnails.default &&
          thumbnails.default.url
          ) {
            thumbnailUrl =
            thumbnails.default.url;
          }
        }

        // --------------------------------------------------------
        // RETURN STATUS
        // --------------------------------------------------------

        return {
          exists: true,
          status: status,
          youtubeVideoId:
          youtubeVideoId.trim(),
          title: title,
          thumbnailUrl: thumbnailUrl,
          scheduledStartTime:
          scheduledStartTime,
          scheduledEndTime:
          scheduledEndTime,
          actualStartTime:
          actualStartTime,
          actualEndTime:
          actualEndTime,
        };
      } catch (error) {
        logger.error(
            "YouTube API request failed.",
            error,
        );

        throw new HttpsError(
            "internal",
            "Unable to check YouTube live status.",
        );
      }
    },
);
