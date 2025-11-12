const functions = require("firebase-functions");
const admin = require("firebase-admin");
const fetch = require("node-fetch");

admin.initializeApp();

exports.autoDeleteImages = functions.pubsub
  .schedule("every 24 hours")
  .onRun(async () => {
    const db = admin.firestore();
    const now = new Date();

    const items = await db.collection("pending_delete").get();

    for (const doc of items.docs) {
      const data = doc.data();
      const deleteAt = data.deleteAt.toDate();
      const expireDays = data.expireDays;

      const age = (now - deleteAt) / (1000 * 60 * 60 * 24);

      if (age >= expireDays) {
        // Delete from Supabase
        await fetch(
          `${functions.config().supabase.url}/storage/v1/object/${data.userId}/${data.fileName}`,
          {
            method: "DELETE",
            headers: {
              Authorization: `Bearer ${functions.config().supabase.service_key}`,
            },
          }
        );

        // Remove from Firebase
        await doc.ref.delete();
      }
    }

    return null;
  });
