// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

document.addEventListener('DOMContentLoaded', function() {
    console.log('JavaScript is working!');
    // debugger;

    const img = new Image();
    img.src = '/assets/cap.jpg';

    img.onload = function() {
        console.log('Image loaded successfully!');
    };

    img.onerror = function() {
        console.log('Error loading image');
    };
});

