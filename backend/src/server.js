import app from "./app.js";
import env from "./config/env.js";
import connectDB from "./config/db.js";
import { seedUsers } from "./data/store.js";

const startServer = async () => {
  try {
    await connectDB();
    await seedUsers();

    app.listen(env.port, "0.0.0.0", () => {
      console.log(`Backend API listening on port ${env.port}`);
    });
  } catch (error) {
    console.error("Failed to start server:", error);
    process.exit(1);
  }
};

startServer();