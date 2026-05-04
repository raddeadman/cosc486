// Storage-related Firebase Functions
import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import * as logger from "firebase-functions/logger";
import { getStorage } from "firebase-admin/storage";
import busboy from "busboy";

// Initialize Firebase Storage with the specified bucket
const bucket = getStorage().bucket("openmarketmobile.firebasestorage.app");

/**
 * StorageService.uploadImageData - HTTP trigger to upload an image
 */
export const uploadImageData = functions.https.onRequest(async (req: any, res: any) => {
  try {
    if (req.method !== "POST") {
      return res.status(405).send("Method Not Allowed");
    }

    // Check for multipart/form-data content type
    const contentType = req.headers['content-type'];
    if (!contentType || !contentType.includes('multipart/form-data')) {
      return res.status(415).json({ error: "Unsupported Media Type" });
    }

    // Get the authorization header for validation
    const authHeader = req.headers.authorization;

    if (authHeader && authHeader.startsWith("Bearer ")) {
      const idToken = authHeader.split("Bearer ")[1];
      try {
        await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        logger.error("Invalid token for image upload", error);
        return res.status(401).json({ error: "Invalid or expired token" });
      }
    }

    // Buffer full body before busboy: streaming req.pipe(bb) often hits
    // "Unexpected end of form" behind Cloud Functions / proxy request handling.
    const rawBody = await new Promise<Buffer>((resolve, reject) => {
      const chunks: Buffer[] = [];
      req.on("data", (chunk: Buffer) => chunks.push(chunk));
      req.on("end", () => resolve(Buffer.concat(chunks)));
      req.on("error", reject);
    });

    if (!rawBody.length) {
      return res.status(400).json({ error: "Empty request body" });
    }

    const bb = busboy({ headers: req.headers });
    let fileBuffer: Buffer | undefined;
    let fileName: string | undefined;

    bb.on("file", (fieldname: string, file: NodeJS.ReadableStream, info: { filename?: string }) => {
      if (fieldname === "file") {
        fileName = info.filename || "upload.bin";
        const chunks: Uint8Array[] = [];

        file.on("data", (chunk: Uint8Array) => {
          chunks.push(chunk);
        });

        file.on("end", () => {
          fileBuffer = Buffer.concat(chunks);
        });
      } else {
        file.resume();
      }
    });

    bb.on("error", (err: Error) => {
      logger.error("Multipart parse error", err);
      if (!res.headersSent) {
        res.status(400).json({ error: err.message || "Invalid multipart body" });
      }
    });

    bb.on("finish", async () => {
      try {
        if (!fileBuffer?.length || !fileName) {
          if (!res.headersSent) {
            return res.status(400).json({ error: "No file provided" });
          }
          return;
        }

        // Create a unique filename
        const fileExtension = fileName.split(".").pop()?.toLowerCase();
        const uniqueFileName = `${Date.now()}.${fileExtension || "jpg"}`;
        const ext = fileExtension || "jpeg";
        const mime =
          ext === "jpg" || ext === "jpeg" ? "image/jpeg" :
            ext === "png" ? "image/png" :
              ext === "gif" ? "image/gif" :
                ext === "webp" ? "image/webp" :
                  `image/${ext}`;

        // Upload to Firebase Storage
        const file = bucket.file(`media-uploads/${uniqueFileName}`);
        await file.save(fileBuffer, {
          metadata: {
            contentType: mime,
            metadata: {
              uploadedBy: (req.headers["x-user-id"] as string) || "anonymous",
            },
          },
        });

        // Make the file publicly accessible
        await file.makePublic();

        // Return the public URL
        if (!res.headersSent) {
          res.status(201).json({
            url: `https://storage.googleapis.com/openmarketmobile.firebasestorage.app/media-uploads/${uniqueFileName}`,
          });
        }
      } catch (error) {
        logger.error("Image upload error", error);
        if (!res.headersSent) {
          return res.status(500).json({ error: "Failed to upload image" });
        }
      }
    });

    bb.end(rawBody);
  } catch (error) {
    logger.error("Upload handler error", error);
    return res.status(500).json({ error: `Upload failed: ${error instanceof Error ? error.message : String(error)}` });
  }
});

