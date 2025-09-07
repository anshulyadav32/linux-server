document.addEventListener('DOMContentLoaded', function() {
    // Domain configuration
    const domains = {
        primary: 'ls.r-u.live',
        github: 'anshulyadav32.github.io/linux-setup'
    };
    
    const currentHost = window.location.hostname;
    const currentPath = window.location.pathname;
    const isGitHubPages = currentHost.includes('github.io');
    const isPrimaryDomain = currentHost === domains.primary;
    
    // Update domain-specific elements
    function updateDomainElements(domain) {
        // Update all elements with domain-url class
        const domainElements = document.querySelectorAll('.domain-url');
        domainElements.forEach(element => {
            element.textContent = domain;
        });
        
        // Update install command
        const installCommand = document.getElementById('install-command');
        if (installCommand) {
            const currentCommand = installCommand.innerHTML;
            const updatedCommand = currentCommand.replace(
                /curl -sSL [^\/]+/,
                `curl -sSL ${domain}`
            );
            installCommand.innerHTML = updatedCommand;
        }
    }
    
    // Create domain switcher functionality
    function initDomainSwitcher() {
        const switchBtn = document.getElementById('domain-switch-btn');
        const currentDomainSpan = document.getElementById('current-domain');
        
        if (switchBtn && currentDomainSpan) {
            // Set current domain display
            currentDomainSpan.textContent = isGitHubPages ? 'GITHUB.IO' : 'LS.R-U.LIVE';
            
            // Add click event
            switchBtn.addEventListener('click', function() {
                const targetDomain = isGitHubPages ? domains.primary : domains.github;
                const protocol = window.location.protocol;
                const targetUrl = `${protocol}//${targetDomain}${currentPath}`;
                
                // Show confirmation
                if (confirm(`Switch to ${isGitHubPages ? 'primary' : 'GitHub Pages'} domain?\n\n${targetUrl}`)) {
                    window.location.href = targetUrl;
                }
            });
        }
    }
    
    // Create notification banner for GitHub Pages
    function createGitHubPagesBanner() {
        if (!isGitHubPages) return;
        
        const banner = document.createElement('div');
        banner.id = 'github-pages-banner';
        banner.style.cssText = `
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 12px 20px;
            text-align: center;
            position: fixed;
            top: 0;
            left: 0;
            width: 100%;
            z-index: 1000;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
            font-family: 'Inter', sans-serif;
        `;
        
        const message = document.createElement('div');
        message.style.cssText = `
            display: flex;
            align-items: center;
            justify-content: center;
            flex-wrap: wrap;
            gap: 15px;
        `;
        
        const textSpan = document.createElement('span');
        textSpan.innerHTML = `
            <i class="fas fa-info-circle" style="margin-right: 8px;"></i>
            You're on the GitHub Pages mirror. For the best experience, visit our primary domain:
        `;
        
        const primaryLink = document.createElement('a');
        primaryLink.href = `https://${domains.primary}${currentPath}`;
        primaryLink.textContent = domains.primary;
        primaryLink.style.cssText = `
            color: #ffeb3b;
            text-decoration: none;
            font-weight: 600;
            border: 1px solid #ffeb3b;
            padding: 4px 12px;
            border-radius: 20px;
            transition: all 0.3s ease;
        `;
        
        primaryLink.addEventListener('mouseenter', function() {
            this.style.background = '#ffeb3b';
            this.style.color = '#333';
        });
        
        primaryLink.addEventListener('mouseleave', function() {
            this.style.background = 'transparent';
            this.style.color = '#ffeb3b';
        });
        
        const closeButton = document.createElement('button');
        closeButton.innerHTML = '<i class="fas fa-times"></i>';
        closeButton.style.cssText = `
            background: rgba(255,255,255,0.2);
            border: none;
            color: white;
            padding: 6px 10px;
            border-radius: 50%;
            cursor: pointer;
            transition: background 0.3s ease;
        `;
        
        closeButton.addEventListener('click', function() {
            banner.remove();
            document.body.style.paddingTop = '0';
            localStorage.setItem('hideBanner', 'true');
        });
        
        closeButton.addEventListener('mouseenter', function() {
            this.style.background = 'rgba(255,255,255,0.3)';
        });
        
        closeButton.addEventListener('mouseleave', function() {
            this.style.background = 'rgba(255,255,255,0.2)';
        });
        
        message.appendChild(textSpan);
        message.appendChild(primaryLink);
        message.appendChild(closeButton);
        banner.appendChild(message);
        
        // Only show if not previously hidden
        if (localStorage.getItem('hideBanner') !== 'true') {
            document.body.insertBefore(banner, document.body.firstChild);
            document.body.style.paddingTop = '60px';
        }
    }
    
    // Initialize domain-specific features
    function initializeDomainFeatures() {
        // Update domain elements based on current domain
        const currentDomain = isGitHubPages ? domains.github.split('/')[0] : domains.primary;
        updateDomainElements(currentDomain);
        
        // Initialize domain switcher
        initDomainSwitcher();
        
        // Show GitHub Pages banner if needed
        createGitHubPagesBanner();
        
        // Add CSS for domain switcher if not exists
        if (!document.getElementById('domain-switcher-styles')) {
            const style = document.createElement('style');
            style.id = 'domain-switcher-styles';
            style.textContent = `
                .domain-switcher {
                    margin-left: auto;
                }
                
                .btn-small {
                    background: rgba(255,255,255,0.1);
                    border: 1px solid rgba(255,255,255,0.3);
                    color: white;
                    padding: 6px 12px;
                    border-radius: 20px;
                    font-size: 12px;
                    cursor: pointer;
                    transition: all 0.3s ease;
                    display: flex;
                    align-items: center;
                    gap: 6px;
                }
                
                .btn-small:hover {
                    background: rgba(255,255,255,0.2);
                    border-color: rgba(255,255,255,0.5);
                }
                
                nav .container {
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                }
                
                nav ul {
                    display: flex;
                    list-style: none;
                    margin: 0;
                    padding: 0;
                    gap: 20px;
                }
                
                @media (max-width: 768px) {
                    .domain-switcher {
                        display: none;
                    }
                    
                    #github-pages-banner .message {
                        flex-direction: column;
                        gap: 10px;
                    }
                }
            `;
            document.head.appendChild(style);
        }
    }
    
    // Initialize everything
    initializeDomainFeatures();
    
    // Handle page visibility change (for when user comes back)
    document.addEventListener('visibilitychange', function() {
        if (!document.hidden && isGitHubPages) {
            // Refresh banner if needed when page becomes visible
            if (!document.getElementById('github-pages-banner') && localStorage.getItem('hideBanner') !== 'true') {
                createGitHubPagesBanner();
            }
        }
    });
});
