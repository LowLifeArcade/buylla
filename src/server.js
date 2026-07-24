import http from 'http';

http.createServer(async (req, resp) => {
    resp.end('Buy Now');
}).listen(3000);
