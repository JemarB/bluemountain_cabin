import { onSchedule, ScheduledEvent } from "firebase-functions/v2/scheduler";
import * as admin from "firebase-admin";

admin.initializeApp();

const TZ = "Jamaica"; // UTC-5, no DST

function ymdInTz(date: Date, tz: string): string {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone: tz,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
  }).formatToParts(date);

  const y = parts.find(p => p.type === "year")!.value;
  const m = parts.find(p => p.type === "month")!.value;
  const d = parts.find(p => p.type === "day")!.value;
  return `${y}-${m}-${d}`;
}

function plusDays(date: Date, days: number): Date {
  const d = new Date(date);
  d.setDate(d.getDate() + days);
  return d;
}

export const autoCancelUnconfirmedBookings = onSchedule(
  { schedule: "0 8 * * *", timeZone: TZ },
  async (event: ScheduledEvent) => {
    const db = admin.firestore();
    const now = new Date();
    const tomorrowYmd = ymdInTz(plusDays(now, 1), TZ);

    const pendingSnap = await db
      .collection("bookings")
      .where("status", "==", "pending")
      .get();

    let cancelled = 0;
    const batch = db.batch();

    pendingSnap.forEach(doc => {
      const data = doc.data();
      const checkIn: Date | undefined = data.checkIn?.toDate?.();
      if (!checkIn) return;

      const ciYmd = ymdInTz(checkIn, TZ);
      if (ciYmd === tomorrowYmd) {
        batch.update(doc.ref, {
          status: "cancelled",
          autoCancelled: true,
          cancelledReason: "Not confirmed 1 day before check-in",
          cancelledAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        cancelled++;
      }
    });

    if (cancelled > 0) {
      await batch.commit();
    }

    console.log(`🚫 Auto-cancelled ${cancelled} unconfirmed bookings for ${tomorrowYmd}.`);
    return;
  }
);
