const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Define the path to the script file
const scriptPath = path.join(__dirname, 'script.lua');

// Route handler for /script GET requests
app.get('/script', (req, res) => {
  // Read the contents of the script file
  fs.readFile(scriptPath, 'utf8', (err, data) => {
    if (err) {
      console.error('Error reading script file:', err);
      res.status(500).send('Internal Server Error');
      return;
    }
    // Set the content type to Lua
    res.set('Content-Type', 'text/plain');
    // Send the script content as response
    res.send(data);
  });
});

// Start the server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
