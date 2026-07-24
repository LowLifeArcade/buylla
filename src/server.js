import http from 'http';
import { DatabaseSync } from 'node:sqlite';
import { randomUUIDv7 } from 'node:crypto';

const { PORT, ENV } = process.env;

const db = new DatabaseSync(':memory:');
db.exec(`
    CREATE TABLE IF NOT EXISTS visitor (
        id TEXT PRIMARY KEY,
        agent TEXT
    )
`);

console.log(randomUUIDv7())

http.createServer(async (req, resp) => {
    const ua = req.headers['user-agent'];
    const cookie = req.headers['cookie']
    db.prepare(`
        INSERT INTO visitor (id, agent)
        VALUES (?, ?)
    `).run(randomUUIDv7(), ua)
    resp.end('Buy Now '+ ua + cookie.split(';').join('\n'));
}).listen(PORT || 4000, () => console.log('running on ' + PORT));
