import pg from 'pg';

export const db = new pg.Pool({
    connectionString: process.env.DATABASE_URL,
});

export async function query(string: string, values: any) {
    return db.query(string, values);
}
