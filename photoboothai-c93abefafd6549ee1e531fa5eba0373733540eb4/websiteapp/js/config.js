/**
 * Photo AI Booth - Configuration
 * Update these values for your n8n instance
 */

const CONFIG = {
    // n8n Webhook URL - Update this to your n8n instance webhook
    WEBHOOK_URL: 'https://petriclucas.app.n8n.cloud/webhook/photo-booth',

    // App branding
    APP_TITLE: 'Photo AI Booth',

    // Expiry time for photos (in seconds) - matches n8n R2 lifecycle
    EXPIRY_SECONDS: 1200, // 20 minutes

    // Countdown timer before capture (in seconds)
    COUNTDOWN_SECONDS: 3,

    // Maximum image size to send (resize if larger)
    MAX_IMAGE_WIDTH: 1920,
    MAX_IMAGE_HEIGHT: 1920,

    // JPEG quality for captured/uploaded images (0-1)
    IMAGE_QUALITY: 0.85,

    // Available filters
    FILTERS: [
        {
            id: 'ocean',
            name: 'Ocean',
            imagePath: 'assets/filters-preview/ocean.png',
            description: 'Underwater ocean adventure'
        },
        {
            id: 'west wild',
            name: 'West Wild',
            imagePath: 'assets/filters-preview/west-wild.png',
            description: 'Wild west adventure'
        },
        {
            id: 'medival',
            name: 'Medieval',
            imagePath: 'assets/filters-preview/medival.png',
            description: 'Medieval castle theme'
        },
        {
            id: 'cyberpunk',
            name: 'Cyberpunk',
            imagePath: 'assets/filters-preview/cyberpunk.png',
            description: 'Futuristic cyberpunk city'
        },
        {
            id: 'beach',
            name: 'Beach',
            imagePath: 'assets/filters-preview/beach.png',
            description: 'Tropical beach paradise'
        },
        {
            id: 'space',
            name: 'Space',
            imagePath: 'assets/filters-preview/space.png',
            description: 'Outer space adventure'
        },
        {
            id: 'superhero',
            name: 'Superhero',
            imagePath: 'assets/filters-preview/superhero.png',
            description: 'Superhero action scene'
        },
        {
            id: 'red carpet',
            name: 'Red Carpet',
            imagePath: 'assets/filters-preview/red-carpet.png',
            description: 'Hollywood red carpet'
        }
    ],

    // Debug mode - set to true for console logging
    DEBUG: false
};

// Freeze config to prevent accidental modification
Object.freeze(CONFIG);
Object.freeze(CONFIG.FILTERS);
