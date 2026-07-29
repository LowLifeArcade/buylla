// import 'dotenv/config';
import pg from 'pg';

export const db = new pg.Pool({
    // connectionString: process.env.DATABASE_URL,
    host: process.env.POSTGRES_HOST ?? 'localhost',
    port: Number(process.env.POSTGRES_PORT ?? 5432),
    user: process.env.POSTGRES_USER,
    password: process.env.POSTGRES_PASSWORD,
    database: process.env.POSTGRES_DB,
});

export async function query(string: string, values?: any) {
    return db.query(string, values);
}
