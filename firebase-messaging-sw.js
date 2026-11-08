// Give the service worker access to Firebase Messaging.
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js');

// Initialize the Firebase app in the service worker
firebase.initializeApp({
  apiKey: "AIzaSyDyivw8v1Wmm51_2qXCMo45AzxmLXXBEYE",
  authDomain: "libraguard-57def.firebaseapp.com",
  projectId: "libraguard-57def",
  storageBucket: "libraguard-57def.firebasestorage.app",
  messagingSenderId: "326585734757",
  appId: "1:326585734757:web:8ba069097cd86f5683d88c",
  measurementId: "G-Y4BG0WNWVC"
});

// Retrieve an instance of Firebase Messaging so that it can handle background messages
const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);

  const title = payload.notification?.title || payload.data?.title || 'LibraGuard';
  const body = payload.notification?.body || payload.data?.body || payload.data?.message || 'New notification from LibraGuard';

  const notificationOptions = {
    body: body,
    icon: 'icons/Icon-192.png',
    badge: 'icons/Icon-192.png',
    tag: payload.data?.entityId || payload.data?.logId || 'libraguard-notification',
    data: {
      ...payload.data,
      click_action: payload.data?.click_action || payload.fcmOptions?.link || './'
    }
  };

  self.registration.showNotification(title, notificationOptions);
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.includes('LibraGuard') && 'focus' in client) {
          return client.focus();
        }
      }
      if (clients.openWindow) {
        return clients.openWindow('./');
      }
    })
  );
});
