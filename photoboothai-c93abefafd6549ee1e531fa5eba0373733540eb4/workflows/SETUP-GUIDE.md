# AI Photo Booth - Setup Guide

## Overview

This workflow processes photos from a tablet web app, applies AI artistic filters using OpenAI, stores results in Cloudflare R2 with privacy protection, and returns a QR code for download.

## Prerequisites

1. **n8n instance** (self-hosted or cloud)
2. **OpenAI API account** with access to image generation
3. **Cloudflare account** with R2 enabled (free tier works)

---

## Step 1: Cloudflare R2 Setup

### 1.1 Create R2 Bucket

1. Log into [Cloudflare Dashboard](https://dash.cloudflare.com)
2. Go to **R2 Object Storage** in the sidebar
3. Click **Create bucket**
4. Name: `photo-booth-temp`
5. Location: Choose nearest to your users
6. **Keep bucket PRIVATE** (do not enable public access)

### 1.2 Configure Lifecycle Rule (Auto-delete after 20 min)

1. Click on your bucket → **Settings**
2. Scroll to **Object lifecycle rules**
3. Click **Add rule**
4. Configure:
   - **Rule name**: `auto-delete-20min`
   - **Prefix**: (leave empty for all objects)
   - **Action**: Delete
   - **Days after object creation**: `0.014` (≈20 minutes)
5. Click **Add rule**

### 1.3 Create API Token

1. Go to **R2** → **Manage R2 API Tokens** → **Create API Token**
2. Configure:
   - **Token name**: `photo-booth-workflow`
   - **Permissions**: Object Read & Write
   - **Specify bucket(s)**: Select `photo-booth-temp`
3. Click **Create API Token**
4. **SAVE THESE VALUES** (shown only once):
   - Access Key ID
   - Secret Access Key
5. Also note your **Account ID** (visible in the R2 dashboard URL or settings)

---

## Step 2: OpenAI API Setup

### 2.1 Get API Key

1. Go to [OpenAI Platform](https://platform.openai.com)
2. Navigate to **API Keys**
3. Click **Create new secret key**
4. Name: `photo-booth`
5. **SAVE THE KEY** (shown only once)

### 2.2 Verify Access

Ensure your account has access to image generation models. Check your usage limits at [Usage page](https://platform.openai.com/usage).

---

## Step 3: n8n Credentials Setup

### 3.1 OpenAI HTTP Header Auth

1. In n8n, go to **Credentials** → **Add Credential**
2. Search for **Header Auth**
3. Configure:
   - **Name**: `OpenAI API Key`
   - **Header Name**: `Authorization`
   - **Header Value**: `Bearer YOUR_OPENAI_API_KEY`
4. Save

### 3.2 Cloudflare R2 S3 Auth

Since R2 is S3-compatible, you can use AWS S3 credentials:

1. In n8n, go to **Credentials** → **Add Credential**
2. Search for **AWS** or **S3**
3. Configure:
   - **Name**: `Cloudflare R2 S3 Auth`
   - **Region**: `auto`
   - **Access Key ID**: Your R2 Access Key ID
   - **Secret Access Key**: Your R2 Secret Access Key
   - **Custom Endpoint**: `https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com`
4. Save

### 3.3 Environment Variables

Set these environment variables in your n8n instance:

```env
R2_ACCOUNT_ID=your_cloudflare_account_id
R2_ACCESS_KEY_ID=your_r2_access_key_id
R2_SECRET_ACCESS_KEY=your_r2_secret_access_key
R2_BUCKET_NAME=photo-booth-temp
```

**How to set in n8n:**
- **Docker**: Add to `docker-compose.yml` or `-e` flags
- **npm**: Add to `.env` file or export in shell
- **n8n Cloud**: Use the environment variables settings

---

## Step 4: Import Workflow

### 4.1 Import the JSON

1. In n8n, click **Add Workflow** → **Import from file**
2. Select `ai-photo-booth.json`
3. Click **Import**

### 4.2 Update Credential References

After import, you need to link the credentials:

1. Click on **HTTP - OpenAI Image Edit** node
2. Under **Authentication**, select your `OpenAI API Key` credential
3. Click on **HTTP - Upload to R2** node
4. Under **Authentication**, select your `Cloudflare R2 S3 Auth` credential
5. Save the workflow

---

## Step 5: Test the Workflow

### 5.1 Get Webhook URL

1. Open the workflow
2. Click on **Webhook - Receive Photo** node
3. Copy the **Test URL** or **Production URL**

### 5.2 Test with curl

```bash
# Create a test image (small base64 encoded)
# Or use a real image encoded as base64

curl -X POST "YOUR_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "image": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==",
    "filter": "cartoon",
    "session_id": "test-123"
  }'
```

### 5.3 Expected Response

```json
{
  "success": true,
  "qr_code": "data:image/png;base64,...",
  "download_url": "https://...r2.cloudflarestorage.com/...?X-Amz-Signature=...",
  "filter_applied": "cartoon",
  "expires_in": 1200,
  "expires_at": "2024-01-15T14:30:00Z",
  "session_id": "test-123"
}
```

---

## Step 6: Activate for Production

1. Test thoroughly with real images
2. Click **Activate** toggle in the workflow
3. Use the **Production URL** instead of Test URL

---

## Available Filters

| Filter | Description |
|--------|-------------|
| `cartoon` | Vibrant cartoon style with bold outlines |
| `oil_painting` | Classic oil painting with brushstrokes |
| `anime` | Japanese anime style |
| `vintage` | 1970s vintage with warm tones |
| `neon` | Cyberpunk neon style |
| `watercolor` | Soft watercolor painting |
| `sketch` | Detailed pencil sketch |
| `pop_art` | Andy Warhol pop art style |

---

## API Contract for Web App

### Endpoint
```
POST https://your-n8n-instance/webhook/photo-booth
```

### Request
```json
{
  "image": "data:image/jpeg;base64,/9j/4AAQ...",
  "filter": "cartoon",
  "session_id": "optional-tracking-id"
}
```

### Success Response (200)
```json
{
  "success": true,
  "qr_code": "data:image/png;base64,...",
  "download_url": "https://...signed-url...",
  "filter_applied": "cartoon",
  "expires_in": 1200,
  "expires_at": "2024-01-15T14:30:00Z",
  "session_id": "optional-tracking-id"
}
```

### Error Response (400/500)
```json
{
  "success": false,
  "error": "Error message",
  "code": "INVALID_INPUT|INVALID_FILTER|PROCESSING_ERROR"
}
```

---

## Privacy & Security

- **Signed URLs**: Download links expire after 20 minutes
- **Auto-deletion**: Files deleted from R2 after 20 minutes
- **Private bucket**: No public access to R2
- **UUID filenames**: Random UUIDs prevent URL guessing
- **No execution logging**: Images not stored in n8n execution history

---

## Troubleshooting

### "Invalid filter" error
- Check that filter name matches exactly (lowercase)
- Valid: `cartoon`, `oil_painting`, `anime`, `vintage`, `neon`, `watercolor`, `sketch`, `pop_art`

### OpenAI API errors
- Verify API key is correct
- Check you have sufficient credits
- Ensure image is valid base64

### R2 upload failures
- Verify bucket name and account ID
- Check API token has write permissions
- Ensure bucket exists

### QR code not generating
- The QR API (qrserver.com) might be rate-limited
- Consider self-hosted QR generator for production

---

## Cost Estimates

### OpenAI
- Image generation: ~$0.04-0.08 per image (varies by model)

### Cloudflare R2
- Storage: Free up to 10GB
- Operations: Free up to 10M reads/1M writes per month
- Egress: Free (no bandwidth charges!)

### Total per photo
- Approximately $0.04-0.10 per photo processed
