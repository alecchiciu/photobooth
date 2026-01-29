/**
 * Photo AI Booth - Camera Module
 * Handles WebRTC camera access, capture, and image processing
 */

const Camera = (function() {
    // Private state
    let stream = null;
    let videoElement = null;
    let canvasElement = null;
    let currentFacingMode = 'user'; // 'user' = front, 'environment' = back
    let hasMultipleCameras = false;

    /**
     * Initialize camera module with DOM elements
     */
    function init(video, canvas) {
        videoElement = video;
        canvasElement = canvas;
        checkMultipleCameras();
    }

    /**
     * Check if device has multiple cameras
     */
    async function checkMultipleCameras() {
        try {
            const devices = await navigator.mediaDevices.enumerateDevices();
            const videoDevices = devices.filter(d => d.kind === 'videoinput');
            hasMultipleCameras = videoDevices.length > 1;
            if (CONFIG.DEBUG) {
                console.log(`Found ${videoDevices.length} camera(s)`);
            }
        } catch (err) {
            console.warn('Could not enumerate devices:', err);
            hasMultipleCameras = false;
        }
    }

    /**
     * Check if camera is supported
     */
    function isSupported() {
        return !!(navigator.mediaDevices && navigator.mediaDevices.getUserMedia);
    }

    /**
     * Start camera stream
     */
    async function start() {
        if (!isSupported()) {
            throw new Error('Camera not supported on this device/browser');
        }

        // Stop any existing stream
        stop();

        const constraints = {
            video: {
                facingMode: currentFacingMode,
                width: { ideal: 1920 },
                height: { ideal: 1080 }
            },
            audio: false
        };

        try {
            stream = await navigator.mediaDevices.getUserMedia(constraints);
            videoElement.srcObject = stream;

            // Wait for video to be ready
            await new Promise((resolve) => {
                videoElement.onloadedmetadata = () => {
                    videoElement.play();
                    resolve();
                };
            });

            if (CONFIG.DEBUG) {
                const track = stream.getVideoTracks()[0];
                const settings = track.getSettings();
                console.log('Camera started:', settings.width, 'x', settings.height);
            }

            return true;
        } catch (err) {
            console.error('Camera access error:', err);

            if (err.name === 'NotAllowedError' || err.name === 'PermissionDeniedError') {
                throw new Error('Camera permission denied. Please allow camera access and try again.');
            } else if (err.name === 'NotFoundError' || err.name === 'DevicesNotFoundError') {
                throw new Error('No camera found on this device.');
            } else if (err.name === 'NotReadableError' || err.name === 'TrackStartError') {
                throw new Error('Camera is in use by another application.');
            } else if (err.name === 'OverconstrainedError') {
                // Try again with less constraints
                return startWithFallback();
            }

            throw new Error('Could not access camera. Please try again.');
        }
    }

    /**
     * Fallback camera start with minimal constraints
     */
    async function startWithFallback() {
        try {
            stream = await navigator.mediaDevices.getUserMedia({
                video: true,
                audio: false
            });
            videoElement.srcObject = stream;
            await videoElement.play();
            return true;
        } catch (err) {
            throw new Error('Could not access camera with fallback settings.');
        }
    }

    /**
     * Stop camera stream
     */
    function stop() {
        if (stream) {
            stream.getTracks().forEach(track => track.stop());
            stream = null;
        }
        if (videoElement) {
            videoElement.srcObject = null;
        }
    }

    /**
     * Flip between front and back camera
     */
    async function flip() {
        if (!hasMultipleCameras) {
            console.warn('Only one camera available');
            return false;
        }

        currentFacingMode = currentFacingMode === 'user' ? 'environment' : 'user';
        await start();
        return true;
    }

    /**
     * Capture photo from video stream
     * Returns base64 data URL
     */
    function capture() {
        if (!stream || !videoElement) {
            throw new Error('Camera not initialized');
        }

        const video = videoElement;
        const canvas = canvasElement;
        const ctx = canvas.getContext('2d');

        // Set canvas size to match video
        canvas.width = video.videoWidth;
        canvas.height = video.videoHeight;

        // Draw video frame to canvas (flip horizontally for front camera)
        if (currentFacingMode === 'user') {
            ctx.translate(canvas.width, 0);
            ctx.scale(-1, 1);
        }
        ctx.drawImage(video, 0, 0);

        // Reset transform
        ctx.setTransform(1, 0, 0, 1, 0, 0);

        // Get data URL
        const dataUrl = canvas.toDataURL('image/jpeg', CONFIG.IMAGE_QUALITY);

        if (CONFIG.DEBUG) {
            console.log('Photo captured:', canvas.width, 'x', canvas.height);
        }

        return dataUrl;
    }

    /**
     * Check if device has multiple cameras
     */
    function canFlip() {
        return hasMultipleCameras;
    }

    /**
     * Get current camera state
     */
    function isActive() {
        return stream !== null && stream.active;
    }

    // Public API
    return {
        init,
        isSupported,
        start,
        stop,
        flip,
        capture,
        canFlip,
        isActive
    };
})();

/**
 * Image utility functions
 */
const ImageUtils = (function() {
    /**
     * Load image from file
     * Returns Promise with base64 data URL
     */
    function loadFromFile(file) {
        return new Promise((resolve, reject) => {
            if (!file || !file.type.startsWith('image/')) {
                reject(new Error('Invalid file type. Please select an image.'));
                return;
            }

            const reader = new FileReader();

            reader.onload = (e) => {
                const img = new Image();
                img.onload = () => {
                    // Resize if needed
                    const resized = resizeImage(img);
                    resolve(resized);
                };
                img.onerror = () => reject(new Error('Could not load image'));
                img.src = e.target.result;
            };

            reader.onerror = () => reject(new Error('Could not read file'));
            reader.readAsDataURL(file);
        });
    }

    /**
     * Resize image if it exceeds max dimensions
     * Returns base64 data URL
     */
    function resizeImage(img) {
        const maxWidth = CONFIG.MAX_IMAGE_WIDTH;
        const maxHeight = CONFIG.MAX_IMAGE_HEIGHT;

        let width = img.width;
        let height = img.height;

        // Calculate new dimensions
        if (width > maxWidth || height > maxHeight) {
            const ratio = Math.min(maxWidth / width, maxHeight / height);
            width = Math.round(width * ratio);
            height = Math.round(height * ratio);
        }

        // Create canvas and draw resized image
        const canvas = document.createElement('canvas');
        canvas.width = width;
        canvas.height = height;

        const ctx = canvas.getContext('2d');
        ctx.drawImage(img, 0, 0, width, height);

        const dataUrl = canvas.toDataURL('image/jpeg', CONFIG.IMAGE_QUALITY);

        if (CONFIG.DEBUG) {
            console.log(`Image resized: ${img.width}x${img.height} -> ${width}x${height}`);
        }

        return dataUrl;
    }

    /**
     * Generate unique session ID
     */
    function generateSessionId() {
        return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
            const r = Math.random() * 16 | 0;
            const v = c === 'x' ? r : (r & 0x3 | 0x8);
            return v.toString(16);
        });
    }

    // Public API
    return {
        loadFromFile,
        resizeImage,
        generateSessionId
    };
})();
