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

    // Process the file using busboy
    const bb = busboy({ headers: req.headers });
    let fileBuffer: Buffer;
    let fileName: string;

    bb.on('file', (fieldname: string, file: any, info: { filename: string }) => {
      if (fieldname === 'file') {
        fileName = info.filename;
        const chunks: Uint8Array[] = [];

        file.on('data', (chunk: Uint8Array) => {
          chunks.push(chunk);
        });

        file.on('end', () => {
          fileBuffer = Buffer.concat(chunks);
        });
      }
    });

    bb.on('finish', async () => {
      try {
        if (!fileBuffer || !fileName) {
          return res.status(400).json({ error: "No file provided" });
        }

        // Create a unique filename
        const fileExtension = fileName.split('.').pop();
        const uniqueFileName = `${Date.now()}.${fileExtension}`;

        // Upload to Firebase Storage
        const file = bucket.file(`media-uploads/${uniqueFileName}`);
        await file.save(fileBuffer, {
          metadata: {
            contentType: 'image/' + (fileExtension || 'jpg'),
            metadata: {
              uploadedBy: req.headers['x-user-id'] || 'anonymous',
            },
          },
        });

        // Make the file publicly accessible
        await file.makePublic();

        // Return the public URL
        res.status(201).json({
          url: `https://storage.googleapis.com/openmarketmobile.firebasestorage.app/media-uploads/${uniqueFileName}`,
        });
      } catch (error) {
        logger.error("Image upload error", error);
        return res.status(500).json({ error: "Failed to upload image" });
      }
    });

    req.pipe(bb);
  } catch (error) {
    logger.error("Upload handler error", error);
    return res.status(500).json({ error: `Upload failed: ${error instanceof Error ? error.message : String(error)}` });
  }
});

