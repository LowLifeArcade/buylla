import 'dotenv/config';

import express from 'express';
import { PlanSchema } from './schema/index.ts';
import { query } from './db/index.ts';

const { PORT, APP_URL } = process.env;

const codes = {
    VALIDATION_ERROR: 'VALIDATION_ERROR',
};

const app = express();

app.use(express.json());

app.get('/', async (req, resp) => {
    const companies = await query('select * from companies');
    resp.send({ companies: companies.rows.map(row => ({ name: row.name })) });
});

app.post('/signup', async (req, resp) => {

    const { name }: { name: string } = req.body;
    const code = name.split(' ').map(part => part.toLowerCase().trim()).join('-');

    const company = await query(
        'insert into companies (code, name) values ($1, $2) returning *',
        [
            code,
            name,
        ],
    );

    resp.send({ company })
});

// app dashboard endpoints

// probably be a different app eventually
app.post('/dashboard/product/:id', (req, resp) => {
    const result = PlanSchema.safeParse(req.body);

    if (!result.success) {
        resp.status(400).send({
            error: {
                code: codes.VALIDATION_ERROR,
                message: 'There was an issue with some fields',
                fields: result.error.issues.map(({ code, message, path }) => ({
                    code,
                    message,
                    field: path.join('.'),
                })),
            },
        });

        return;
    }
    // session has client data like business the product will be for
    // plan.id should be for that company only so it can be anything but cannot be duplicate for that company
    // how do we have unique('company-name', 'premium-plan')

    resp.send({ message: 'done' });
});

app.get('/dashboard/products', async (req, resp) => {
    resp.json([]);
});

// client endpoints

/**
    we have nested products that are delivered to client calling /products
    products
        offer one
            abandonment
            special offer
        offer two
            abandoment
            special offer
 */
app.get('/app/products', (req, resp) => {
    // client product should be scalted down for client
    resp.send([
        {
            name: 'premium',
            price: 1000,
        },
    ]);
});

app.post('/app/checkout/:transactionId', async (req, resp) => {
    console.log(req.params.transactionId);
    resp.send({ message: 'done' });
});

app.listen(PORT, () => {
    const url = APP_URL + ':' + PORT;

    const link = `\u001b]8;;${url}\u001b\\${url}\u001b]8;;\u001b\\`;

    console.log(`running on port ${PORT}. Open ${link}`);
});
