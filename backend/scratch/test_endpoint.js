const http = require('http');

http.get('http://localhost:5000/api/v1/admin/video-assignments/stats', (res) => {
  let data = '';
  res.on('data', (chunk) => data += chunk);
  res.on('end', () => {
    console.log('Status code:', res.statusCode);
    console.log('Response body:', data);
  });
}).on('error', (err) => {
  console.error('Error:', err.message);
});
