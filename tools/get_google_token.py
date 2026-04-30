#!/usr/bin/env python3
"""
Google Photos OAuth2 Token Helper for Shawnee Channel
=====================================================
Run this script once to obtain a refresh token for the Cloudflare Worker.

Prerequisites:
1. Go to https://console.cloud.google.com/
2. Create a project (or use an existing one)
3. Enable the "Photos Library API"
4. Go to Credentials → Create Credentials → OAuth 2.0 Client ID
5. Application type: "Desktop app"
6. Download or copy the client_id and client_secret

Usage:
    python3 tools/get_google_token.py

After running, store the output values as Cloudflare Worker secrets:
    wrangler secret put GOOGLE_CLIENT_ID
    wrangler secret put GOOGLE_CLIENT_SECRET
    wrangler secret put GOOGLE_REFRESH_TOKEN
    wrangler secret put GOOGLE_ALBUM_ID
"""

import http.server
import json
import sys
import threading
import urllib.parse
import urllib.request
import webbrowser

# Google OAuth2 endpoints
AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth"
TOKEN_URL = "https://oauth2.googleapis.com/token"
PHOTOS_API = "https://photoslibrary.googleapis.com/v1"

# Scopes needed for read-only access to shared albums
SCOPES = "https://www.googleapis.com/auth/photoslibrary.readonly https://www.googleapis.com/auth/photoslibrary.sharing"

# Local redirect server
REDIRECT_PORT = 8099
REDIRECT_URI = f"http://localhost:{REDIRECT_PORT}/callback"


def get_credentials():
    """Prompt user for OAuth credentials."""
    print("\n=== Google Photos OAuth2 Setup ===\n")
    client_id = input("Enter your Google OAuth Client ID: ").strip()
    client_secret = input("Enter your Google OAuth Client Secret: ").strip()

    if not client_id or not client_secret:
        print("Error: Both client_id and client_secret are required.")
        sys.exit(1)

    return client_id, client_secret


def start_auth_flow(client_id):
    """Open browser for user consent and capture the auth code."""
    params = urllib.parse.urlencode({
        "client_id": client_id,
        "redirect_uri": REDIRECT_URI,
        "response_type": "code",
        "scope": SCOPES,
        "access_type": "offline",
        "prompt": "consent",
    })

    auth_url = f"{AUTH_URL}?{params}"
    print(f"\nOpening browser for Google authorization...")
    print(f"If it doesn't open, visit:\n{auth_url}\n")

    # Capture the auth code via a local HTTP server
    auth_code = {"value": None}
    server_ready = threading.Event()

    class CallbackHandler(http.server.BaseHTTPRequestHandler):
        def do_GET(self):
            parsed = urllib.parse.urlparse(self.path)
            query = urllib.parse.parse_qs(parsed.query)

            if "code" in query:
                auth_code["value"] = query["code"][0]
                self.send_response(200)
                self.send_header("Content-Type", "text/html")
                self.end_headers()
                self.wfile.write(b"<h1>Success!</h1><p>You can close this tab and return to the terminal.</p>")
            else:
                error = query.get("error", ["unknown"])[0]
                self.send_response(400)
                self.send_header("Content-Type", "text/html")
                self.end_headers()
                self.wfile.write(f"<h1>Error: {error}</h1>".encode())

            # Shutdown server after handling
            threading.Thread(target=self.server.shutdown).start()

        def log_message(self, format, *args):
            pass  # Suppress request logging

    server = http.server.HTTPServer(("localhost", REDIRECT_PORT), CallbackHandler)

    # Start server in background
    server_thread = threading.Thread(target=server.serve_forever)
    server_thread.start()

    # Open browser
    webbrowser.open(auth_url)

    # Wait for callback
    print("Waiting for authorization...")
    server_thread.join(timeout=120)

    if auth_code["value"] is None:
        print("Error: Timed out waiting for authorization.")
        sys.exit(1)

    return auth_code["value"]


def exchange_code(client_id, client_secret, auth_code):
    """Exchange authorization code for access + refresh tokens."""
    data = urllib.parse.urlencode({
        "client_id": client_id,
        "client_secret": client_secret,
        "code": auth_code,
        "grant_type": "authorization_code",
        "redirect_uri": REDIRECT_URI,
    }).encode()

    req = urllib.request.Request(TOKEN_URL, data=data, method="POST")
    req.add_header("Content-Type", "application/x-www-form-urlencoded")

    try:
        with urllib.request.urlopen(req) as resp:
            tokens = json.loads(resp.read())
    except urllib.error.HTTPError as e:
        error_body = e.read().decode()
        print(f"Error exchanging code: {e.code}\n{error_body}")
        sys.exit(1)

    return tokens


def list_albums(access_token):
    """List user's albums so they can pick one."""
    albums = []
    next_page = None

    while True:
        url = f"{PHOTOS_API}/albums?pageSize=50"
        if next_page:
            url += f"&pageToken={next_page}"

        req = urllib.request.Request(url)
        req.add_header("Authorization", f"Bearer {access_token}")

        try:
            with urllib.request.urlopen(req) as resp:
                data = json.loads(resp.read())
        except urllib.error.HTTPError as e:
            print(f"Error listing albums: {e.code}")
            return albums

        for album in data.get("albums", []):
            albums.append({
                "id": album["id"],
                "title": album.get("title", "(Untitled)"),
                "count": album.get("mediaItemsCount", "0"),
            })

        next_page = data.get("nextPageToken")
        if not next_page:
            break

    # Also list shared albums
    url = f"{PHOTOS_API}/sharedAlbums?pageSize=50"
    req = urllib.request.Request(url)
    req.add_header("Authorization", f"Bearer {access_token}")

    try:
        with urllib.request.urlopen(req) as resp:
            data = json.loads(resp.read())
            for album in data.get("sharedAlbums", []):
                albums.append({
                    "id": album["id"],
                    "title": album.get("title", "(Untitled Shared)") + " [SHARED]",
                    "count": album.get("mediaItemsCount", "0"),
                })
    except urllib.error.HTTPError:
        pass

    return albums


def main():
    client_id, client_secret = get_credentials()
    auth_code = start_auth_flow(client_id)

    print("\nExchanging authorization code for tokens...")
    tokens = exchange_code(client_id, client_secret, auth_code)

    access_token = tokens.get("access_token")
    refresh_token = tokens.get("refresh_token")

    if not refresh_token:
        print("Warning: No refresh token received. Make sure 'prompt=consent' was used.")
        print("You may need to revoke access and try again.")
        sys.exit(1)

    print("\n" + "=" * 60)
    print("SUCCESS! Tokens obtained.")
    print("=" * 60)

    # List albums
    print("\nFetching your albums...")
    albums = list_albums(access_token)

    if albums:
        print(f"\nFound {len(albums)} album(s):\n")
        for i, album in enumerate(albums, 1):
            print(f"  {i}. {album['title']} ({album['count']} items)")
            print(f"     ID: {album['id']}")
        print()

        # Let user pick
        try:
            choice = input("Enter album number for the slideshow (or press Enter to skip): ").strip()
            if choice:
                idx = int(choice) - 1
                selected_album = albums[idx]
                print(f"\nSelected: {selected_album['title']}")
            else:
                selected_album = None
        except (ValueError, IndexError):
            selected_album = None
    else:
        print("\nNo albums found. You can set the album ID manually later.")
        selected_album = None

    # Print final instructions
    print("\n" + "=" * 60)
    print("STORE THESE AS CLOUDFLARE WORKER SECRETS:")
    print("=" * 60)
    print(f"\n  GOOGLE_CLIENT_ID:     {client_id}")
    print(f"  GOOGLE_CLIENT_SECRET: {client_secret}")
    print(f"  GOOGLE_REFRESH_TOKEN: {refresh_token}")
    if selected_album:
        print(f"  GOOGLE_ALBUM_ID:      {selected_album['id']}")
    else:
        print(f"  GOOGLE_ALBUM_ID:      (set this manually)")

    print("\nRun these commands in your Cloudflare Worker directory:")
    print(f'  wrangler secret put GOOGLE_CLIENT_ID')
    print(f'  wrangler secret put GOOGLE_CLIENT_SECRET')
    print(f'  wrangler secret put GOOGLE_REFRESH_TOKEN')
    print(f'  wrangler secret put GOOGLE_ALBUM_ID')
    print()


if __name__ == "__main__":
    main()
