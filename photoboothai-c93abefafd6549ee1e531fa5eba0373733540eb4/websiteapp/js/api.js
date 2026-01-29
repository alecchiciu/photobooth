/**
 * Photo AI Booth - API Module
 * Handles communication with n8n webhook
 */

const API = (function() {
    /**
     * Process photo with selected filter
     * @param {string} imageDataUrl - Base64 encoded image
     * @param {string} filter - Filter ID to apply
     * @param {string} sessionId - Unique session identifier
     * @returns {Promise<Object>} - API response
     */
    async function processPhoto(imageDataUrl, filter, sessionId) {
        if (!CONFIG.WEBHOOK_URL || CONFIG.WEBHOOK_URL.includes('your-n8n-instance')) {
            throw new Error('Webhook URL not configured. Please update config.js with your n8n webhook URL.');
        }

        const payload = {
            image: imageDataUrl,
            filter: filter,
            session_id: sessionId,
            model: 'gemini'  // Use 'gpt' for GPT Image 1.5 or 'gemini' for Nano Banana (requires paid tier)
        };

        if (CONFIG.DEBUG) {
            console.log('Sending to webhook:', {
                url: CONFIG.WEBHOOK_URL,
                filter: filter,
                sessionId: sessionId,
                imageSize: Math.round(imageDataUrl.length / 1024) + 'KB'
            });
        }

        try {
            const response = await fetch(CONFIG.WEBHOOK_URL, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(payload)
            });

            // Parse response
            const data = await response.json();

            if (CONFIG.DEBUG) {
                console.log('API Response:', data);
            }

            // Check for success
            if (!response.ok) {
                throw new Error(data.error || `Server error: ${response.status}`);
            }

            if (!data.success) {
                throw new Error(data.error || 'Processing failed');
            }

            // Validate response has required fields
            if (!data.qr_code) {
                throw new Error('Invalid response: missing QR code');
            }

            return {
                success: true,
                qrCode: data.qr_code,
                previewImage: data.preview_image,
                downloadUrl: data.download_url,
                filterApplied: data.filter_applied || filter,
                expiresIn: data.expires_in || CONFIG.EXPIRY_SECONDS,
                expiresAt: data.expires_at ? new Date(data.expires_at) : null,
                sessionId: data.session_id || sessionId
            };

        } catch (err) {
            if (CONFIG.DEBUG) {
                console.error('API Error:', err);
            }

            // Handle specific error types
            if (err.name === 'TypeError' && err.message.includes('fetch')) {
                throw new Error('Network error. Please check your internet connection.');
            }

            if (err.message.includes('CORS')) {
                throw new Error('Server configuration error. Please contact support.');
            }

            throw err;
        }
    }

    /**
     * Test webhook connectivity
     * @returns {Promise<boolean>}
     */
    async function testConnection() {
        try {
            const response = await fetch(CONFIG.WEBHOOK_URL, {
                method: 'OPTIONS'
            });
            return response.ok || response.status === 405; // 405 = method not allowed but server responds
        } catch {
            return false;
        }
    }

    /**
     * Format error message for display
     * @param {Error} error
     * @returns {string}
     */
    function formatError(error) {
        const message = error.message || 'An unexpected error occurred';

        // Map technical errors to user-friendly messages
        const errorMap = {
            'INVALID_INPUT': 'The image format is not supported. Please try a different photo.',
            'INVALID_FILTER': 'The selected filter is not available. Please choose another.',
            'PROCESSING_ERROR': 'Could not process the image. Please try again.',
            'Failed to fetch': 'Could not connect to server. Please check your internet.',
            'NetworkError': 'Network error. Please check your connection and try again.',
            'timeout': 'Request timed out. Please try again.'
        };

        for (const [key, value] of Object.entries(errorMap)) {
            if (message.includes(key)) {
                return value;
            }
        }

        return message;
    }

    // Public API
    return {
        processPhoto,
        testConnection,
        formatError
    };
})();
