require('dotenv').config();
const imagekit = require('./config/imagekit');
console.log('Testing imagekit upload...');
imagekit.upload({
    file: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
    fileName: 'test.png',
    folder: '/TEST'
}, (error, result) => {
    if (error) {
        console.error('Error:', error);
    } else {
        console.log('Success:', result.url);
    }
});
