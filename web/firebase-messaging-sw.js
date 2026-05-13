importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.12.0/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyBBLnF3uALzo5NPzTm1eRcfD2uPpjpU6nE",
  authDomain: "mtcapp-df2d2.firebaseapp.com",
  projectId: "mtcapp-df2d2",
  storageBucket: "mtcapp-df2d2.firebasestorage.app",
  messagingSenderId: "1094753995290",
  appId: "1:1094753995290:web:10c32e90d5d0899cbe1fa3",
  measurementId: "G-BGX795E2R5"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage(function(payload) {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
    icon: '/icons/Icon-192.png'
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
