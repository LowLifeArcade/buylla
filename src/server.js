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
    `).run(randomUUIDv7(), ua);

    const visitors = db.prepare('SELECT * FROM visitor').all();
    console.log(`🚀 | visitors:`, visitors.map(v => v.id +  v.agent))
    resp.end('Buy Now '+ ua + cookie?.split(';').join('\n') + visitors.map(v => v.id +  v.agent).toString());
}).listen(PORT || 4000, () => console.log('running on ' + PORT));
