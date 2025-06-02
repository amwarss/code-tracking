const CONFIG = {
    PHONE_DIGITS: 10 
};

let isUIOpen = false;
let resourceName = null;
let playerData = null;

function getResourceName() {
    if (resourceName) return resourceName;
    
    if (window.GetParentResourceName) {
        resourceName = window.GetParentResourceName();
    } else {
        resourceName = 'code-tracking';
    }
    return resourceName;
}

async function sendNUIMessage(endpoint, data = {}) {
    const fullURL = `https://${getResourceName()}/${endpoint}`;
    
    try {
        const response = await fetch(fullURL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify(data)
        });
        
        if (response.ok) {
            return await response.json();
        } else {
            throw new Error(`HTTP Error: ${response.status}`);
        }
    } catch (error) {
        return { success: false, message: 'Connection error' };
    }
}

function showUI() {
    const ui = document.getElementById('trackerUI');
    if (!ui) return;
    
    ui.classList.add('show');
    isUIOpen = true;
    document.body.style.cursor = 'default';
    
    resetForm();
    
    loadPlayerData();
    
    if (typeof SetNuiFocus !== 'undefined') {
        SetNuiFocus(true, true);
    }
}

function closeUI() {
    const ui = document.getElementById('trackerUI');
    if (!ui) return;
    
    ui.classList.remove('show');
    isUIOpen = false;
    
    document.body.style.cursor = 'none';
    
    resetForm();
    
    if (typeof SetNuiFocus !== 'undefined') {
        SetNuiFocus(false, false);
    }
    
    sendNUIMessage('closeUI').catch(() => {});
}

function resetForm() {
    const phoneInput = document.getElementById('phoneNumber');
    const loading = document.getElementById('loading');
    const trackingStatus = document.getElementById('trackingStatus');
    
    if (phoneInput) phoneInput.value = '';
    if (loading) loading.style.display = 'none';
    if (trackingStatus) trackingStatus.textContent = 'STANDBY';
}

async function loadPlayerData() {
    try {
        const data = await sendNUIMessage('getPlayerData');
        if (data && data.job) {
            playerData = data;
            updateUIWithPlayerData(data);
        }
    } catch (error) {}
}

function updateUIWithPlayerData(data) {
}

window.addEventListener('message', function(event) {
    if (!event.data) return;
    
    const data = event.data;
    
    switch(data.type) {
        case 'showUI':
            showUI();
            break;
        case 'hideUI':
        case 'closeUI':
            closeUI();
            break;
        case 'trackingStarted':
            handleTrackingStarted(data);
            break;
        case 'trackingEnded':
            handleTrackingEnded();
            break;
        case 'updateStatus':
            updateTrackingStatus(data.status);
            break;
        default:
    }
});

function handleTrackingStarted(data) {
    const trackingStatus = document.getElementById('trackingStatus');
    if (trackingStatus) {
        trackingStatus.textContent = 'TARGET ACQUIRED';
    }
    
    showNotification('The tracking process has been successfully initiated', 'success');
    
    setTimeout(() => {
        if (isUIOpen) {
            closeUI();
        }
    }, 2000);
}

function handleTrackingEnded() {
    const trackingStatus = document.getElementById('trackingStatus');
    if (trackingStatus) {
        trackingStatus.textContent = 'STANDBY';
    }
    
    showNotification('The tracking process has ended', 'info');
}

function updateTrackingStatus(status) {
    const trackingStatus = document.getElementById('trackingStatus');
    if (trackingStatus) {
        trackingStatus.textContent = status.toUpperCase();
    }
}

document.addEventListener('keydown', function(event) {
    if (event.key === 'Escape' && isUIOpen) {
        event.preventDefault();
        event.stopPropagation();
        
        closeUI();
        
        setTimeout(() => {
            if (typeof SetNuiFocus !== 'undefined') {
                SetNuiFocus(false, false);
            }
        }, 100);
    }
});

document.addEventListener('contextmenu', function(event) {
    if (isUIOpen) {
        event.preventDefault();
    }
});

function showNotification(message, type = 'success', duration = 3000) {
    const existingNotifications = document.querySelectorAll('.notification');
    existingNotifications.forEach(notif => {
        if (document.body.contains(notif)) {
            document.body.removeChild(notif);
        }
    });
    
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    document.body.appendChild(notification);
    
    setTimeout(() => notification.classList.add('show'), 100);
    
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => {
            if (document.body.contains(notification)) {
                document.body.removeChild(notification);
            }
        }, 300);
    }, duration);
}

async function startTracking() {
    const phoneInput = document.getElementById('phoneNumber');
    const loading = document.getElementById('loading');
    const trackingStatus = document.getElementById('trackingStatus');
    const trackButton = document.querySelector('.track-button');
    
    if (!phoneInput || !loading || !trackingStatus || !trackButton) {
        return;
    }
    
    const phoneNumber = phoneInput.value.trim();
    
    if (!phoneNumber) {
        showNotification('Please enter the phone number', 'error');
        phoneInput.focus();
        return;
    }
    
    if (phoneNumber.length !== CONFIG.PHONE_DIGITS) {
        showNotification(`The phone number must be${CONFIG.PHONE_DIGITS} number`, 'error');
        phoneInput.focus();
        return;
    }
    
    const phonePattern = new RegExp(`^\\d{${CONFIG.PHONE_DIGITS}}$`);
    if (!phonePattern.test(phoneNumber)) {
        showNotification('The phone number must contain numbers only', 'error');
        phoneInput.focus();
        return;
    }
    
    loading.style.display = 'block';
    trackingStatus.textContent = 'PROCESSING...';
    trackButton.disabled = true;
    trackButton.style.opacity = '0.6';
    trackButton.textContent = 'PROCESSING...';
    
    try {
        const result = await sendNUIMessage('startTracking', {
            phoneNumber: phoneNumber
        });
        
        if (result && result.success) {
            trackingStatus.textContent = 'TARGET ACQUIRED';
            showNotification(result.message || 'The tracking process has started successfully', 'success');
            
            phoneInput.value = '';
            
            setTimeout(() => {
                if (isUIOpen) {
                    closeUI();
                }
            }, 100);
            
        } else {
            trackingStatus.textContent = 'FAILED';
            showNotification(result.message || 'Failed in the tracking operation', 'error');
        }
        
    } catch (error) {
        trackingStatus.textContent = 'ERROR';
        showNotification('حدث خطأ في الاتصال', 'error');
    } finally {
        loading.style.display = 'none';
        trackButton.disabled = false;
        trackButton.style.opacity = '1';
        trackButton.textContent = 'INITIATE TRACKING';
        
        setTimeout(() => {
            if (trackingStatus.textContent === 'FAILED' || trackingStatus.textContent === 'ERROR') {
                trackingStatus.textContent = 'STANDBY';
            }
        }, 3000);
    }
}

function setupPhoneInput() {
    const phoneInput = document.getElementById('phoneNumber');
    if (!phoneInput) return;
    
    phoneInput.addEventListener('input', function(e) {
        let value = e.target.value.replace(/\D/g, '');
        if (value.length > CONFIG.PHONE_DIGITS) value = value.slice(0, CONFIG.PHONE_DIGITS);
        e.target.value = value;
        
        if (value.length === CONFIG.PHONE_DIGITS) {
            e.target.style.borderColor = '#00ff00';
        } else {
            e.target.style.borderColor = 'rgba(0, 255, 0, 0.3)';
        }
    });
    
    phoneInput.addEventListener('keypress', function(e) {
        if (e.key === 'Enter') {
            e.preventDefault();
            startTracking();
        }
    });
    
    phoneInput.addEventListener('paste', function(e) {
        e.preventDefault();
        const paste = (e.clipboardData || window.clipboardData).getData('text');
        const numbers = paste.replace(/\D/g, '').slice(0, CONFIG.PHONE_DIGITS);
        e.target.value = numbers;
        e.target.dispatchEvent(new Event('input'));
    });
}

function startDynamicEffects() {
    setInterval(() => {
        if (isUIOpen) {
            const statusDots = document.querySelectorAll('.status-dot');
            statusDots.forEach((dot, index) => {
                setTimeout(() => {
                    dot.style.boxShadow = '0 0 10px #00ff00';
                    setTimeout(() => {
                        dot.style.boxShadow = 'none';
                    }, 200);
                }, index * 100);
            });
        }
    }, 3000);
    
    setInterval(() => {
        if (isUIOpen) {
            const radarCircles = document.querySelectorAll('.radar-circle');
            radarCircles.forEach((circle, index) => {
                setTimeout(() => {
                    circle.style.borderWidth = '3px';
                    circle.style.borderColor = 'rgba(0, 255, 0, 0.8)';
                    setTimeout(() => {
                        circle.style.borderWidth = '2px';
                        circle.style.borderColor = 'rgba(0, 255, 0, 0.3)';
                    }, 300);
                }, index * 150);
            });
        }
    }, 4000);
}

function triggerGlitchEffect() {
    const screen = document.querySelector('.screen');
    if (!screen) return;
    
    screen.style.filter = 'hue-rotate(90deg) saturate(1.5)';
    setTimeout(() => {
        screen.style.filter = 'none';
    }, 200);
}

document.addEventListener('DOMContentLoaded', function() {
    setupPhoneInput();
    
    startDynamicEffects();
    
    const closeButton = document.querySelector('.close-button');
    if (closeButton) {
        closeButton.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            closeUI();
        });
    }
    
    const trackButton = document.querySelector('.track-button');
    if (trackButton) {
        trackButton.addEventListener('click', startTracking);
    }
    
    const form = document.querySelector('.tracking-form');
    if (form) {
        form.addEventListener('submit', function(e) {
            e.preventDefault();
            startTracking();
        });
    }
    
    document.addEventListener('focusin', function(e) {
        if (isUIOpen && e.target.tagName === 'INPUT') {
            e.target.style.boxShadow = '0 0 20px rgba(0, 255, 0, 0.5)';
        }
    });
    
    document.addEventListener('focusout', function(e) {
        if (e.target.tagName === 'INPUT') {
            e.target.style.boxShadow = 'none';
        }
    });
});

if (typeof window !== 'undefined' && window.location.protocol === 'file:') {
    window.testShowUI = function() {
        window.dispatchEvent(new MessageEvent('message', {
            data: { type: 'showUI' }
        }));
    };
    
    window.testCloseUI = function() {
        closeUI();
    };
}

function cleanup() {
    isUIOpen = false;
    resourceName = null;
    playerData = null;
    
    const phoneInput = document.getElementById('phoneNumber');
    if (phoneInput) {
        phoneInput.value = '';
    }
    
    if (typeof SetNuiFocus !== 'undefined') {
        SetNuiFocus(false, false);
    }
    
    document.body.style.cursor = 'none';
}

window.showUI = showUI;
window.closeUI = closeUI;
window.startTracking = startTracking;