/**
 * Photo AI Booth - Main Application
 * Handles screen navigation, user interactions, and app state
 */

const App = (function() {
    // DOM Elements
    const elements = {
        screens: {},
        buttons: {},
        displays: {}
    };

    // App State
    const state = {
        currentScreen: 'welcome',
        capturedImage: null,
        selectedFilter: null,
        sessionId: null,
        expiryTimer: null,
        expiryInterval: null
    };

    /**
     * Initialize the application
     */
    function init() {
        cacheElements();
        bindEvents();
        initCamera();
        renderFilters();
        initFilterKeyboardNav();

        if (CONFIG.DEBUG) {
            console.log('Photo AI Booth initialized');
            console.log('Webhook URL:', CONFIG.WEBHOOK_URL);
        }
    }

    /**
     * Cache DOM elements for performance
     */
    function cacheElements() {
        // Screens
        elements.screens = {
            welcome: document.getElementById('screen-welcome'),
            filterSelection: document.getElementById('screen-filter-selection'),
            captureChoice: document.getElementById('screen-capture-choice'),
            camera: document.getElementById('screen-camera'),
            filters: document.getElementById('screen-filters'),
            processing: document.getElementById('screen-processing'),
            result: document.getElementById('screen-result'),
            error: document.getElementById('screen-error')
        };

        // Buttons
        elements.buttons = {
            getStarted: document.getElementById('btn-get-started'),
            continueToCapture: document.getElementById('btn-continue-to-capture'),
            choiceCamera: document.getElementById('btn-choice-camera'),
            choiceUpload: document.getElementById('btn-choice-upload'),
            backToFilters: document.getElementById('btn-back-to-filters'),
            cameraBack: document.getElementById('btn-camera-back'),
            cameraFlip: document.getElementById('btn-camera-flip'),
            capture: document.getElementById('btn-capture'),
            retake: document.getElementById('btn-retake'),
            applyFilter: document.getElementById('btn-apply-filter'),
            newPhoto: document.getElementById('btn-new-photo'),
            tryAgain: document.getElementById('btn-try-again')
        };

        // Display elements
        elements.displays = {
            cameraPreview: document.getElementById('camera-preview'),
            cameraCanvas: document.getElementById('camera-canvas'),
            countdownOverlay: document.getElementById('countdown-overlay'),
            countdownNumber: document.getElementById('countdown-number'),
            filterCarousel: document.getElementById('filter-carousel'),
            currentFilterName: document.getElementById('current-filter-name'),
            selectedFilterBadge: document.getElementById('selected-filter-badge-text'),
            photoPreview: document.getElementById('photo-preview'),
            filtersGrid: document.getElementById('filters-grid'),
            processingStatus: document.getElementById('processing-status'),
            qrCode: document.getElementById('qr-code'),
            previewImage: document.getElementById('preview-image'),
            expiryTime: document.getElementById('expiry-time'),
            filterApplied: document.getElementById('filter-applied'),
            errorMessage: document.getElementById('error-message'),
            fileInput: document.getElementById('file-input')
        };
    }

    /**
     * Bind event listeners
     */
    function bindEvents() {
        // Welcome screen
        elements.buttons.getStarted.addEventListener('click', handleGetStarted);

        // Filter selection screen
        elements.buttons.continueToCapture.addEventListener('click', handleContinueToCapture);

        // Capture choice screen
        elements.buttons.choiceCamera.addEventListener('click', handleChoiceCamera);
        elements.buttons.choiceUpload.addEventListener('click', handleChoiceUpload);
        elements.buttons.backToFilters.addEventListener('click', handleBackToFilters);

        // Camera screen
        elements.buttons.cameraBack.addEventListener('click', handleCameraBack);
        elements.buttons.cameraFlip.addEventListener('click', handleCameraFlip);
        elements.buttons.capture.addEventListener('click', handleCapture);

        // Old filter screen (now skipped in normal flow)
        elements.buttons.retake.addEventListener('click', handleRetake);
        elements.buttons.applyFilter.addEventListener('click', handleApplyFilter);

        // Result screen
        elements.buttons.newPhoto.addEventListener('click', handleNewPhoto);

        // Error screen
        elements.buttons.tryAgain.addEventListener('click', handleTryAgain);

        // File input
        elements.displays.fileInput.addEventListener('change', handleFileSelected);

        // Carousel scroll detection
        if (elements.displays.filterCarousel) {
            elements.displays.filterCarousel.addEventListener('scroll', handleCarouselScroll);
        }
    }

    /**
     * Initialize camera module
     */
    function initCamera() {
        Camera.init(
            elements.displays.cameraPreview,
            elements.displays.cameraCanvas
        );

        // Show/hide flip button based on camera availability
        if (!Camera.canFlip()) {
            elements.buttons.cameraFlip.style.visibility = 'hidden';
        }
    }

    /**
     * Render filter options in carousel
     */
    function renderFilters() {
        const carousel = elements.displays.filterCarousel;
        if (!carousel) return;

        carousel.innerHTML = '';

        CONFIG.FILTERS.forEach((filter, index) => {
            const card = document.createElement('button');
            card.className = 'filter-card';
            if (index === 0) card.classList.add('center'); // First card starts centered
            card.dataset.filterId = filter.id;
            card.setAttribute('role', 'option');
            card.setAttribute('aria-label', `${filter.name}: ${filter.description}`);
            card.setAttribute('aria-selected', 'false');

            // Create image element
            const img = document.createElement('img');
            img.className = 'filter-image';
            img.alt = filter.name;
            img.src = filter.imagePath;
            img.loading = index > 2 ? 'lazy' : 'eager';

            // Handle image load errors
            img.addEventListener('error', () => {
                if (CONFIG.DEBUG) console.warn(`Failed to load: ${filter.imagePath}`);
                card.style.background = 'var(--color-surface)';
                card.innerHTML = `<div style="color: var(--color-text); padding: 20px;">${filter.name}</div>`;
            });

            // Create name overlay
            const nameOverlay = document.createElement('div');
            nameOverlay.className = 'filter-name-overlay';
            nameOverlay.textContent = filter.name;

            // Assemble card
            card.appendChild(img);
            card.appendChild(nameOverlay);

            // Click handler
            card.addEventListener('click', () => selectFilterCard(filter.id));

            carousel.appendChild(card);
        });

        // Set initial filter name display
        if (CONFIG.FILTERS.length > 0) {
            elements.displays.currentFilterName.textContent = CONFIG.FILTERS[0].name;
        }
    }

    /**
     * Handle Get Started button - go to filter selection
     */
    function handleGetStarted() {
        showScreen('filterSelection');
    }

    /**
     * Handle carousel scroll - detect centered card
     */
    function handleCarouselScroll() {
        const carousel = elements.displays.filterCarousel;
        const cards = carousel.querySelectorAll('.filter-card');
        const carouselCenter = carousel.offsetLeft + carousel.offsetWidth / 2;

        let centerCard = null;
        let minDistance = Infinity;

        cards.forEach(card => {
            const cardCenter = card.offsetLeft + card.offsetWidth / 2 - carousel.scrollLeft;
            const distance = Math.abs(carouselCenter - cardCenter);

            if (distance < minDistance) {
                minDistance = distance;
                centerCard = card;
            }
        });

        // Update center class
        cards.forEach(card => card.classList.remove('center'));
        if (centerCard) {
            centerCard.classList.add('center');
            const filterId = centerCard.dataset.filterId;
            const filter = CONFIG.FILTERS.find(f => f.id === filterId);
            if (filter) {
                elements.displays.currentFilterName.textContent = filter.name;
            }
        }
    }

    /**
     * Select a filter card
     */
    function selectFilterCard(filterId) {
        state.selectedFilter = filterId;

        // Update UI
        const cards = elements.displays.filterCarousel.querySelectorAll('.filter-card');
        cards.forEach(card => {
            const isSelected = card.dataset.filterId === filterId;
            card.classList.toggle('selected', isSelected);
            card.setAttribute('aria-selected', isSelected.toString());
        });

        // Scroll to center
        const selectedCard = elements.displays.filterCarousel.querySelector(`[data-filter-id="${filterId}"]`);
        if (selectedCard) {
            selectedCard.scrollIntoView({
                behavior: 'smooth',
                block: 'nearest',
                inline: 'center'
            });
        }

        // Enable continue button
        elements.buttons.continueToCapture.disabled = false;

        if (CONFIG.DEBUG) {
            console.log('Selected filter:', filterId);
        }
    }

    /**
     * Handle Continue button - go to capture choice screen
     */
    function handleContinueToCapture() {
        if (!state.selectedFilter) return;

        // Update badge text
        const filter = CONFIG.FILTERS.find(f => f.id === state.selectedFilter);
        if (filter) {
            elements.displays.selectedFilterBadge.textContent = `${filter.name} Filter`;
        }

        showScreen('captureChoice');
    }

    /**
     * Handle camera choice - start camera
     */
    async function handleChoiceCamera() {
        try {
            showScreen('camera');
            await Camera.start();
        } catch (err) {
            showError(err.message);
        }
    }

    /**
     * Handle upload choice - trigger file input
     */
    function handleChoiceUpload() {
        elements.displays.fileInput.click();
    }

    /**
     * Handle back to filters - return to filter selection
     */
    function handleBackToFilters() {
        showScreen('filterSelection');
    }

    /**
     * Navigate to a screen
     */
    function showScreen(screenName) {
        // Hide all screens
        Object.values(elements.screens).forEach(screen => {
            screen.classList.remove('active');
        });

        // Show target screen
        const targetScreen = elements.screens[screenName];
        if (targetScreen) {
            targetScreen.classList.add('active');
            state.currentScreen = screenName;
        }

        if (CONFIG.DEBUG) {
            console.log('Screen:', screenName);
        }
    }

    /**
     * Handle file selection
     */
    async function handleFileSelected(e) {
        const file = e.target.files[0];
        if (!file) return;

        try {
            const imageDataUrl = await ImageUtils.loadFromFile(file);
            state.capturedImage = imageDataUrl;
            state.sessionId = ImageUtils.generateSessionId();

            // Go directly to processing (filter already selected)
            if (state.selectedFilter) {
                handleApplyFilter();
            } else {
                showError('Please select a filter first');
            }
        } catch (err) {
            showError(err.message);
        }

        // Reset file input
        e.target.value = '';
    }

    /**
     * Handle camera back button
     */
    function handleCameraBack() {
        Camera.stop();
        showScreen('captureChoice');
    }

    /**
     * Handle camera flip button
     */
    async function handleCameraFlip() {
        try {
            await Camera.flip();
        } catch (err) {
            console.warn('Could not flip camera:', err);
        }
    }

    /**
     * Handle capture button
     */
    async function handleCapture() {
        // Show countdown
        await showCountdown();

        // Capture image
        try {
            state.capturedImage = Camera.capture();
            state.sessionId = ImageUtils.generateSessionId();
            Camera.stop();

            // Go directly to processing (filter already selected)
            if (state.selectedFilter) {
                handleApplyFilter();
            } else {
                showError('Please select a filter first');
            }
        } catch (err) {
            showError(err.message);
        }
    }

    /**
     * Show countdown animation
     */
    function showCountdown() {
        return new Promise((resolve) => {
            const overlay = elements.displays.countdownOverlay;
            const number = elements.displays.countdownNumber;
            let count = CONFIG.COUNTDOWN_SECONDS;

            overlay.classList.remove('hidden');
            number.textContent = count;

            const interval = setInterval(() => {
                count--;
                if (count > 0) {
                    number.textContent = count;
                    // Re-trigger animation
                    number.style.animation = 'none';
                    number.offsetHeight; // Trigger reflow
                    number.style.animation = 'countdownPulse 1s ease-in-out';
                } else {
                    clearInterval(interval);
                    overlay.classList.add('hidden');
                    resolve();
                }
            }, 1000);
        });
    }

    /**
     * Show filter selection screen
     */
    function showFilterScreen() {
        elements.displays.photoPreview.src = state.capturedImage;
        state.selectedFilter = null;
        elements.buttons.applyFilter.disabled = true;

        // Clear previous selection
        document.querySelectorAll('.filter-card').forEach(card => {
            card.classList.remove('selected');
            card.setAttribute('aria-selected', 'false');
        });

        showScreen('filters');
    }

    /**
     * Select a filter
     */
    function selectFilter(filterId) {
        state.selectedFilter = filterId;

        // Update UI and ARIA states
        document.querySelectorAll('.filter-card').forEach(card => {
            const isSelected = card.dataset.filterId === filterId;
            card.classList.toggle('selected', isSelected);
            card.setAttribute('aria-selected', isSelected.toString());
        });

        elements.buttons.applyFilter.disabled = false;

        // Scroll selected card to center of viewport
        const selectedCard = document.querySelector(`[data-filter-id="${filterId}"]`);
        if (selectedCard) {
            selectedCard.scrollIntoView({
                behavior: 'smooth',
                block: 'nearest',
                inline: 'center'
            });
        }

        if (CONFIG.DEBUG) {
            console.log('Selected filter:', filterId);
        }
    }

    /**
     * Initialize keyboard navigation for filter selection
     */
    function initFilterKeyboardNav() {
        const carousel = elements.displays.filterCarousel;
        if (!carousel) return;

        carousel.addEventListener('keydown', (e) => {
            const cards = Array.from(carousel.querySelectorAll('.filter-card'));
            const currentIndex = cards.findIndex(card => card === document.activeElement);

            let nextIndex = currentIndex;

            switch(e.key) {
                case 'ArrowLeft':
                    e.preventDefault();
                    nextIndex = Math.max(0, currentIndex - 1);
                    break;
                case 'ArrowRight':
                    e.preventDefault();
                    nextIndex = Math.min(cards.length - 1, currentIndex + 1);
                    break;
                case 'Enter':
                case ' ':
                    e.preventDefault();
                    if (currentIndex >= 0) {
                        selectFilterCard(cards[currentIndex].dataset.filterId);
                    }
                    return;
            }

            if (nextIndex !== currentIndex && cards[nextIndex]) {
                cards[nextIndex].focus();
                cards[nextIndex].scrollIntoView({
                    behavior: 'smooth',
                    block: 'nearest',
                    inline: 'center'
                });
            }
        });
    }

    /**
     * Handle retake button
     */
    function handleRetake() {
        state.capturedImage = null;
        showScreen('captureChoice');
    }

    /**
     * Handle apply filter button
     */
    async function handleApplyFilter() {
        if (!state.selectedFilter || !state.capturedImage) {
            return;
        }

        showScreen('processing');
        updateProcessingStatus('Uploading image...');

        try {
            updateProcessingStatus('Applying AI magic...');

            const result = await API.processPhoto(
                state.capturedImage,
                state.selectedFilter,
                state.sessionId
            );

            showResult(result);
        } catch (err) {
            showError(API.formatError(err));
        }
    }

    /**
     * Update processing status text
     */
    function updateProcessingStatus(text) {
        elements.displays.processingStatus.textContent = text;
    }

    /**
     * Show result screen
     */
    function showResult(result) {
        // Display QR code
        elements.displays.qrCode.src = result.qrCode;

        // Display preview image
        if (result.previewImage) {
            elements.displays.previewImage.src = result.previewImage;
        }

        // Display filter name
        const filterConfig = CONFIG.FILTERS.find(f => f.id === result.filterApplied);
        elements.displays.filterApplied.textContent = filterConfig ? filterConfig.name : result.filterApplied;

        // Start expiry timer
        startExpiryTimer(result.expiresIn);

        showScreen('result');
    }

    /**
     * Start expiry countdown timer
     */
    function startExpiryTimer(seconds) {
        // Clear any existing timer
        if (state.expiryInterval) {
            clearInterval(state.expiryInterval);
        }

        let remaining = seconds;
        updateExpiryDisplay(remaining);

        state.expiryInterval = setInterval(() => {
            remaining--;
            updateExpiryDisplay(remaining);

            if (remaining <= 0) {
                clearInterval(state.expiryInterval);
                elements.displays.expiryTime.textContent = 'Expired';
            }
        }, 1000);
    }

    /**
     * Update expiry time display
     */
    function updateExpiryDisplay(seconds) {
        const mins = Math.floor(seconds / 60);
        const secs = seconds % 60;
        elements.displays.expiryTime.textContent =
            `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }

    /**
     * Handle new photo button
     */
    function handleNewPhoto() {
        resetState();
        showScreen('filterSelection');
    }

    /**
     * Handle try again button
     */
    function handleTryAgain() {
        // If we have a captured image, go back to filters
        if (state.capturedImage) {
            showFilterScreen();
        } else {
            resetState();
            showScreen('welcome');
        }
    }

    /**
     * Show error screen
     */
    function showError(message) {
        elements.displays.errorMessage.textContent = message;
        Camera.stop();
        showScreen('error');
    }

    /**
     * Reset app state
     */
    function resetState() {
        state.capturedImage = null;
        state.selectedFilter = null;
        state.sessionId = null;

        if (state.expiryInterval) {
            clearInterval(state.expiryInterval);
            state.expiryInterval = null;
        }

        Camera.stop();
    }

    // Initialize on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }

    // Public API (for debugging)
    return {
        getState: () => ({ ...state }),
        showScreen,
        resetState
    };
})();
