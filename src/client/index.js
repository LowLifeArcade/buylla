const resp = await fetch('http://localhost:4000/product/123', {
    method: 'post',
    headers: {
        'content-type': 'application/json'
    },
    body: JSON.stringify({
        name: 'plus'
    })
});
console.log(`🚀 | resp:`, await resp.json())
