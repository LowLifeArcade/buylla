import dotenv from 'dotenv';
import express from 'express';

dotenv.config();

const { PORT, ENV } = process.env;

const app = express();

app.use(express.json())

app.get('/', async (req, resp) => {
    resp.send({ message: 'home ' });
});

app.get('/products', (req, resp) => {
    resp.send([
        {
            name: "premium",
            price: 1000,
        }
    ])
});

app.post('/product/:id', (req, resp) => {
    console.log('id', req.params.id)
    console.log('body', req.body)
    resp.send({ message: 'done'})
})

app.listen(PORT, () => `running on port ${PORT}`);
