import { hashPassword } from "../utils/password.js";
import User from "../models/User.js";

export const ROLES = Object.freeze({
  ADMIN: "ADMIN",
  EXAMINER: "EXAMINER",
  CLIENT: "CLIENT",
  STUDENT: "STUDENT",
});

/**
 * Seeds default development users into MongoDB if no users exist.
 * Called once after database connection is established.
 */
export async function seedUsers() {
  const count = await User.countDocuments();
  if (count > 0) return;

  const defaults = [
    { email: "admin@example.com", password: "admin123", role: ROLES.ADMIN },
    {
      email: "examiner@example.com",
      password: "examiner123",
      role: ROLES.EXAMINER,
    },
    {
      email: "student@example.com",
      password: "student123",
      role: ROLES.STUDENT,
    },
    {
      email: "student2@example.com",
      password: "student123",
      role: ROLES.STUDENT,
    },
  ];

  const docs = defaults.map(({ email, password, role }) => ({
    email,
    username: email.split("@")[0],
    passwordHash: hashPassword(password),
    role,
    active: true,
  }));

  try {
    await User.insertMany(docs, { ordered: false });
    console.log(`Seeded ${docs.length} default users into MongoDB.`);
  } catch (err) {
    // Code 11000 = duplicate key — users already exist, safe to ignore
    if (err.code === 11000) {
      console.log("Default users already exist, skipping seed.");
    } else {
      throw err;
    }
  }
}

/**
 * Drops all collections — use only in tests.
 */
export async function resetStore() {
  const collections = await import("mongoose").then(
    (m) => m.default.connection.collections,
  );
  for (const key of Object.keys(collections)) {
    await collections[key].deleteMany({});
  }
  await seedUsers();
}
