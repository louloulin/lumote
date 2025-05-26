// Sample Blinko Plugin - Note Counter
// This demonstrates the plugin development workflow

const samplePlugin = {
  id: 'note-counter',
  name: 'Note Counter',
  version: '1.0.0',
  description: 'Displays the total number of notes in the system',
  author: 'Blinko Dev Team',
  
  // Plugin lifecycle methods
  onLoad() {
    console.log('Note Counter plugin loaded');
    this.initializeCounter();
  },
  
  onUnload() {
    console.log('Note Counter plugin unloaded');
    this.cleanup();
  },
  
  // Plugin-specific methods
  initializeCounter() {
    // Add a counter widget to the sidebar
    const counterElement = document.createElement('div');
    counterElement.id = 'note-counter-widget';
    counterElement.className = 'plugin-widget';
    counterElement.innerHTML = `
      <div class="widget-header">
        <h3>📊 Note Counter</h3>
      </div>
      <div class="widget-content">
        <div class="counter-display">
          <span class="count-number" id="note-count">Loading...</span>
          <span class="count-label">Total Notes</span>
        </div>
        <button onclick="noteCounterPlugin.refreshCount()" class="refresh-btn">
          🔄 Refresh
        </button>
      </div>
    `;
    
    // Find sidebar and append the widget
    const sidebar = document.querySelector('.sidebar') || document.querySelector('[data-sidebar]');
    if (sidebar) {
      sidebar.appendChild(counterElement);
    }
    
    // Initial count load
    this.refreshCount();
    
    // Auto-refresh every 30 seconds
    this.refreshInterval = setInterval(() => {
      this.refreshCount();
    }, 30000);
  },
  
  async refreshCount() {
    try {
      // Use the Blinko API to get note count
      const response = await fetch('/api/trpc/notes.count', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
        },
      });
      
      if (response.ok) {
        const data = await response.json();
        const count = data.result?.data?.json || 0;
        
        const countElement = document.getElementById('note-count');
        if (countElement) {
          countElement.textContent = count.toLocaleString();
          countElement.classList.add('updated');
          setTimeout(() => countElement.classList.remove('updated'), 500);
        }
      } else {
        console.error('Failed to fetch note count');
        const countElement = document.getElementById('note-count');
        if (countElement) {
          countElement.textContent = 'Error';
        }
      }
    } catch (error) {
      console.error('Error fetching note count:', error);
      const countElement = document.getElementById('note-count');
      if (countElement) {
        countElement.textContent = 'Error';
      }
    }
  },
  
  cleanup() {
    // Clear refresh interval
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval);
    }
    
    // Remove widget from DOM
    const widget = document.getElementById('note-counter-widget');
    if (widget) {
      widget.remove();
    }
  },
  
  // Plugin settings
  getSettings() {
    return {
      refreshInterval: {
        type: 'number',
        label: 'Refresh Interval (seconds)',
        default: 30,
        min: 5,
        max: 300,
      },
      showInSidebar: {
        type: 'boolean',
        label: 'Show in Sidebar',
        default: true,
      },
      displayFormat: {
        type: 'select',
        label: 'Display Format',
        options: [
          { value: 'number', label: 'Number only' },
          { value: 'formatted', label: 'Formatted with commas' },
          { value: 'abbreviated', label: 'Abbreviated (1K, 1M)' },
        ],
        default: 'formatted',
      },
    };
  },
  
  // Handle settings changes
  onSettingsChange(settings) {
    console.log('Plugin settings updated:', settings);
    
    // Update refresh interval
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval);
    }
    
    if (settings.refreshInterval) {
      this.refreshInterval = setInterval(() => {
        this.refreshCount();
      }, settings.refreshInterval * 1000);
    }
    
    // Toggle sidebar visibility
    const widget = document.getElementById('note-counter-widget');
    if (widget) {
      widget.style.display = settings.showInSidebar ? 'block' : 'none';
    }
  },
  
  // Plugin API methods that can be called by other plugins
  getAPI() {
    return {
      getCurrentCount: () => {
        const countElement = document.getElementById('note-count');
        return countElement ? parseInt(countElement.textContent.replace(/,/g, '')) : 0;
      },
      
      forceRefresh: () => {
        this.refreshCount();
      },
      
      subscribe: (callback) => {
        // Allow other plugins to subscribe to count updates
        if (!this.subscribers) {
          this.subscribers = [];
        }
        this.subscribers.push(callback);
      },
    };
  },
};

// Plugin CSS styles
const pluginStyles = `
  .plugin-widget {
    background: var(--bg-secondary, #f8f9fa);
    border: 1px solid var(--border-color, #e9ecef);
    border-radius: 8px;
    padding: 16px;
    margin: 12px 0;
    box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
  }
  
  .widget-header h3 {
    margin: 0 0 12px 0;
    font-size: 14px;
    font-weight: 600;
    color: var(--text-primary, #333);
  }
  
  .counter-display {
    text-align: center;
    padding: 20px 0;
  }
  
  .count-number {
    display: block;
    font-size: 32px;
    font-weight: bold;
    color: var(--accent-color, #0066cc);
    line-height: 1;
    transition: all 0.3s ease;
  }
  
  .count-number.updated {
    transform: scale(1.1);
    color: var(--success-color, #28a745);
  }
  
  .count-label {
    display: block;
    font-size: 12px;
    color: var(--text-secondary, #666);
    margin-top: 8px;
    text-transform: uppercase;
    letter-spacing: 0.5px;
  }
  
  .refresh-btn {
    width: 100%;
    padding: 8px 12px;
    background: var(--bg-primary, #fff);
    border: 1px solid var(--border-color, #ddd);
    border-radius: 4px;
    cursor: pointer;
    font-size: 12px;
    transition: all 0.2s ease;
  }
  
  .refresh-btn:hover {
    background: var(--bg-hover, #f0f0f0);
    border-color: var(--border-hover, #bbb);
  }
  
  .refresh-btn:active {
    transform: translateY(1px);
  }
`;

// Plugin manifest for the Blinko plugin system
const pluginManifest = {
  id: 'note-counter',
  name: 'Note Counter',
  version: '1.0.0',
  description: 'Displays the total number of notes in the system with real-time updates',
  author: 'Blinko Dev Team',
  homepage: 'https://github.com/blinko-space/blinko-plugins/note-counter',
  repository: 'https://github.com/blinko-space/blinko-plugins/note-counter',
  license: 'MIT',
  keywords: ['statistics', 'counter', 'dashboard', 'widget'],
  
  // Plugin requirements
  requirements: {
    blinkoVersion: '>=1.0.0',
    permissions: ['notes.read', 'ui.sidebar'],
  },
  
  // Plugin files
  files: {
    main: 'index.js',
    styles: 'styles.css',
    manifest: 'plugin.json',
  },
  
  // Plugin configuration schema
  configSchema: {
    type: 'object',
    properties: {
      refreshInterval: {
        type: 'number',
        minimum: 5,
        maximum: 300,
        default: 30,
        title: 'Refresh Interval (seconds)',
        description: 'How often to update the note count',
      },
      showInSidebar: {
        type: 'boolean',
        default: true,
        title: 'Show in Sidebar',
        description: 'Display the widget in the sidebar',
      },
      displayFormat: {
        type: 'string',
        enum: ['number', 'formatted', 'abbreviated'],
        default: 'formatted',
        title: 'Display Format',
        description: 'How to format the note count display',
      },
    },
  },
  
  // Plugin lifecycle hooks
  hooks: {
    onLoad: 'onLoad',
    onUnload: 'onUnload',
    onSettingsChange: 'onSettingsChange',
  },
  
  // Plugin API exports
  api: {
    getCurrentCount: 'getCurrentCount',
    forceRefresh: 'forceRefresh',
    subscribe: 'subscribe',
  },
};

// Export for CommonJS
if (typeof module !== 'undefined' && module.exports) {
  module.exports = {
    plugin: samplePlugin,
    styles: pluginStyles,
    manifest: pluginManifest,
  };
}

// Export for ES6 modules
if (typeof window !== 'undefined') {
  window.noteCounterPlugin = samplePlugin;
}

// Auto-register with Blinko plugin system
if (typeof globalThis !== 'undefined' && globalThis.BlinkoPluginRegistry) {
  globalThis.BlinkoPluginRegistry.register(pluginManifest, samplePlugin);
}
