/**
 * Shawnee Photos Worker
 * 
 * Cloudflare Worker that fetches photos from a public Google Drive folder
 * and returns a JSON list of image URLs for the Roku channel.
 * 
 * Required secrets (set via `wrangler secret put`):
 *   GOOGLE_API_KEY      - Google Cloud API key (restricted to Drive API)
 *   GOOGLE_FOLDER_ID    - Google Drive folder ID (from the folder URL)
 * 
 * Required KV namespace:
 *   PHOTO_CACHE (binding)
 */

const DRIVE_API = "https://www.googleapis.com/drive/v3";
const CACHE_KEY = "folder_photos";

export default {
  async fetch(request, env) {
    // Only allow GET requests
    if (request.method !== "GET") {
      return new Response("Method not allowed", { status: 405 });
    }

    // CORS headers
    const headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Cache-Control": "public, max-age=600",
    };

    try {
      // Check KV cache first
      const cached = await env.PHOTO_CACHE.get(CACHE_KEY);
      if (cached) {
        const parsed = JSON.parse(cached);
        return new Response(JSON.stringify({ ...parsed, source: "cache" }), { headers });
      }

      // Fetch photos from Google Drive folder
      const photos = await fetchFolderPhotos(env.GOOGLE_API_KEY, env.GOOGLE_FOLDER_ID);

      // Build response
      const result = {
        photos: photos,
        count: photos.length,
        cached_at: new Date().toISOString(),
      };

      // Cache in KV (default 1 hour)
      const ttl = parseInt(env.CACHE_TTL_SECONDS) || 3600;
      await env.PHOTO_CACHE.put(CACHE_KEY, JSON.stringify(result), {
        expirationTtl: ttl,
      });

      return new Response(JSON.stringify({ ...result, source: "fresh" }), { headers });

    } catch (error) {
      return new Response(
        JSON.stringify({ error: error.message, photos: [], count: 0 }),
        { status: 500, headers }
      );
    }
  },
};

/**
 * Fetch all image files from a public Google Drive folder.
 * Returns an array of direct-download URLs sized for 1920x1080.
 */
async function fetchFolderPhotos(apiKey, folderId) {
  const photos = [];
  let pageToken = null;

  do {
    // Query for image files in the folder
    const query = `'${folderId}' in parents and mimeType contains 'image/' and trashed = false`;
    const params = new URLSearchParams({
      q: query,
      key: apiKey,
      fields: "nextPageToken,files(id,name,mimeType,thumbnailLink)",
      pageSize: "100",
      orderBy: "createdTime desc",
    });

    if (pageToken) {
      params.set("pageToken", pageToken);
    }

    const response = await fetch(`${DRIVE_API}/files?${params.toString()}`);

    if (!response.ok) {
      const error = await response.text();
      throw new Error(`Drive API error: ${response.status} - ${error}`);
    }

    const data = await response.json();

    if (data.files) {
      for (const file of data.files) {
        // Use the thumbnail link resized to 1920px wide
        // Google Drive thumbnail URLs support =s{size} or =w{width}-h{height}
        if (file.thumbnailLink) {
          // Replace the default size with 1920 wide
          const url = file.thumbnailLink.replace(/=s\d+$/, "=s1920");
          photos.push(url);
        } else {
          // Fallback: use the direct download link via export
          photos.push(
            `https://drive.google.com/thumbnail?id=${file.id}&sz=w1920`
          );
        }
      }
    }

    pageToken = data.nextPageToken || null;
  } while (pageToken);

  return photos;
}
