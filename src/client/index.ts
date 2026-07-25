import type { Plan } from '../schema/index.ts';

async function main() {
    const plan: Plan = {
        name: 'plus',
        id: '',
        // price: 10000,
    };

    const resp = await fetch('http://localhost:4000/dashboard/product/123', {
        method: 'post',
        headers: {
            'content-type': 'application/json',
        },
        body: JSON.stringify(plan),
    });

    const json = await resp.json();
    console.log(`🚀 | resp:`, json.error);

    if (!resp.ok) {
        return;
    }

    console.log('successful creation')
}

main();