import http from 'http';

const { PORT } = process.env;

http.createServer(async (req, resp) => {
    resp.end('Buy Now');
}).listen(PORT || 4000, () => console.log('running on ' + PORT));
