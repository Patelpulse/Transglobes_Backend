importScripts("https://www.gstatic.com/firebasejs/9.1.3/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/9.1.3/firebase-messaging-compat.js");

firebase.initializeApp({
    apiKey: 'AIzaSyBnml6vJJQz05so1pNmsyLpLCqdcFM6RAQ',
    appId: '1:531372125872:web:348b0f06ba434b74021575',
    messagingSenderId: '531372125872',
    projectId: 'transgolbe-a1eeb',
    authDomain: 'transgolbe-a1eeb.firebaseapp.com',
    storageBucket: 'transgolbe-a1eeb.firebasestorage.app',
    measurementId: 'G-RW1D2MLE7Z',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
    console.log('[firebase-messaging-sw.js] Received background message ', payload);
    const notificationTitle = payload.notification.title;
    const notificationOptions = {
        body: payload.notification.body,
        icon: '/icons/Icon-192.png'
    };

    return self.registration.showNotification(notificationTitle, notificationOptions);
});
