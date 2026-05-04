// Storage-related Firebase Functions
import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import * as logger from "firebase-functions/logger";
import { getStorage } from "firebase-admin/storage";
import busboy from "busboy";

// Initialize Firebase Storage with the specified bucket
const bucket = getStorage().bucket("openmarketmobile.firebasestorage.app");

/** Gen-2 / some proxies attach a full body buffer; use it when present so we never hang on a drained stream. */
function getRawBody(req: functions.https.Request): Buffer | undefined {
  const raw = (req as unknown as { rawBody?: Buffer }).rawBody;
  return Buffer.isBuffer(raw) && raw.length ? raw : undefined;
}

/**
 * StorageService.uploadImageData - HTTP trigger to upload an image
 * Longer timeout: buffer + parse + GCS write + makePublic() can exceed default 60s on cold starts / large files.
 */
export const uploadImageData = functions
  .runWith({ timeoutSeconds: 120, memory: "512MB" })
  .https.onRequest(async (req, res) => {
    try {
      if (req.method !== "POST") {
        res.status(405).send("Method Not Allowed");
        return;
      }

      const contentType = req.headers["content-type"];
      if (!contentType || !contentType.includes("multipart/form-data")) {
        res.status(415).json({ error: "Unsupported Media Type" });
        return;
      }

      const authHeader = req.headers.authorization;
      if (authHeader && authHeader.startsWith("Bearer ")) {
        const idToken = authHeader.split("Bearer ")[1];
        try {
          await admin.auth().verifyIdToken(idToken);
        } catch (error) {
          logger.error("Invalid token for image upload", error);
          res.status(401).json({ error: "Invalid or expired token" });
          return;
        }
      }

      let rawBody = getRawBody(req);
      if (!rawBody) {
        rawBody = await new Promise<Buffer>((resolve, reject) => {
          const chunks: Buffer[] = [];
          req.on("data", (chunk: Buffer) => chunks.push(chunk));
          req.on("end", () => resolve(Buffer.concat(chunks)));
          req.on("error", reject);
        });
      }

      if (!rawBody.length) {
        res.status(400).json({ error: "Empty request body" });
        return;
      }

      // IMPORTANT: await this Promise. If the outer async handler returns before
      // busboy 'finish' + GCS upload complete, the invocation can end without sending a response → client timeout.
      await new Promise<void>((resolve) => {
        let settled = false;
        const settle = () => {
          if (settled) return;
          settled = true;
          resolve();
        };

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
          settle();
        });

        bb.on("finish", () => {
          void (async () => {
            try {
              if (!fileBuffer?.length || !fileName) {
                if (!res.headersSent) {
                  res.status(400).json({ error: "No file provided" });
                }
                return;
              }

              const fileExtension = fileName.split(".").pop()?.toLowerCase();
              const uniqueFileName = `${Date.now()}.${fileExtension || "jpg"}`;
              const ext = fileExtension || "jpeg";
              const mime =
                ext === "jpg" || ext === "jpeg" ? "image/jpeg" :
                  ext === "png" ? "image/png" :
                    ext === "gif" ? "image/gif" :
                      ext === "webp" ? "image/webp" :
                        `image/${ext}`;

              const file = bucket.file(`media-uploads/${uniqueFileName}`);
              await file.save(fileBuffer, {
                metadata: {
                  contentType: mime,
                  metadata: {
                    uploadedBy: (req.headers["x-user-id"] as string) || "anonymous",
                  },
                },
              });

              await file.makePublic();

              if (!res.headersSent) {
                res.status(201).json({
                  url: `https://storage.googleapis.com/openmarketmobile.firebasestorage.app/media-uploads/${uniqueFileName}`,
                });
              }
            } catch (error) {
              logger.error("Image upload error", error);
              if (!res.headersSent) {
                res.status(500).json({ error: "Failed to upload image" });
              }
            } finally {
              settle();
            }
          })();
        });

        bb.end(rawBody);
      });
    } catch (error) {
      logger.error("Upload handler error", error);
      if (!res.headersSent) {
        res.status(500).json({ error: `Upload failed: ${error instanceof Error ? error.message : String(error)}` });
      }
    }
  });
