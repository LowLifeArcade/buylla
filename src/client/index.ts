import type { Plan } from '../schema/index.ts';

async function main() {
    const plan: Plan = {
        name: 'plus',
        id: '',
        // price: 10000,
    };

    const requests = {
        plan: {
            body: plan,
            url: 'dashboard/product/123',
            method: 'post'
        },
        signup: {
            url: 'signup',
            method: 'post',
            body: {
                name: 'Acme One'
            }
        }
    }

    const host = {
        dev: 'http://localhost:4000/',
        prod: 'https://buylla.onrender.com/',
    }
    const request = requests.signup;

    const reqUrl = `${host.prod}${request.url}`;
    console.log({
        reqUrl,
        body: request.body
    })
    const resp = await fetch(reqUrl, {
        method: request.method,
        headers: {
            'content-type': 'application/json',
        },
        body: JSON.stringify(request.body),
    });

    const json = await resp.json();
    console.log(`🚀 | resp:`, json.error);

    if (!resp.ok) {
        return;
    }

    console.log('successful creation')
}

main();