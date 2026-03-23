importScripts('https://www.gstatic.com/firebasejs/9.1.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.1.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyBcc-cYJ-xfLYwo8Jyc6eZmgk918j0WL28",
  authDomain: "mera-ubar.firebaseapp.com",
  projectId: "mera-ubar",
  storageBucket: "mera-ubar.firebasestorage.app",
  messagingSenderId: "1072284227316",
  appId: "1:1072284227316:android:967e253fa09ff7e4cd30a1"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
