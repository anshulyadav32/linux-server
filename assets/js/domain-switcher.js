document.addEventListener('DOMContentLoaded', function() {
    // Check if we're on GitHub Pages domain
    const currentHost = window.location.hostname;
    const currentPath = window.location.pathname;
    const isGitHubPages = currentHost.includes('github.io');
    
    if (isGitHubPages) {
        // Create a banner to inform visitors about the primary domain
        const banner = document.createElement('div');
        banner.style.backgroundColor = '#f8f9fa';
        banner.style.padding = '10px';
        banner.style.textAlign = 'center';
        banner.style.borderBottom = '1px solid #ddd';
        banner.style.position = 'fixed';
        banner.style.top = '0';
        banner.style.left = '0';
        banner.style.width = '100%';
        banner.style.zIndex = '1000';
        
        // Create message
        const message = document.createElement('p');
        message.style.margin = '0';
        message.innerHTML = 'You\'re viewing this site on GitHub Pages. Visit our primary domain: <a href="https://ls.r-u.live' + currentPath + '" style="color: #3366cc; font-weight: bold;">ls.r-u.live</a>';
        
        // Create close button
        const closeButton = document.createElement('button');
        closeButton.innerHTML = '×';
        closeButton.style.position = 'absolute';
        closeButton.style.right = '10px';
        closeButton.style.top = '10px';
        closeButton.style.background = 'none';
        closeButton.style.border = 'none';
        closeButton.style.fontSize = '20px';
        closeButton.style.cursor = 'pointer';
        closeButton.onclick = function() {
            banner.style.display = 'none';
            // Add padding back to body
            document.body.style.paddingTop = '0';
        };
        
        // Add elements to banner
        banner.appendChild(message);
        banner.appendChild(closeButton);
        
        // Add banner to page
        document.body.insertBefore(banner, document.body.firstChild);
        
        // Add padding to body to prevent content from being hidden under banner
        document.body.style.paddingTop = banner.offsetHeight + 'px';
    }
});
