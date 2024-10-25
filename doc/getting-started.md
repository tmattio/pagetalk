# Getting Started Guide

## Setting Up PageTalk for Your Website

### 1. Add the Client Library

Add the following to your HTML page where you want comments to appear:

```html
<!-- Add the styles -->
<link rel="stylesheet" href="http://your-server.com/pagetalk.css">

<!-- Add the container -->
<div id="pagetalk-comments"></div>

<!-- Add the script -->
<script src="http://your-server.com/pagetalk.js"></script>

<!-- Initialize PageTalk -->
<script>
const pageTalk = new PageTalk({
  serverUrl: 'http://your-server.com',
  containerId: 'pagetalk-comments'
});
pageTalk.init();
</script>
```

### 2. Styling

PageTalk provides default styles but can be customized using CSS:

```css
/* Example customization */
.pagetalk-container {
  max-width: 800px;
  margin: 2rem auto;
}

.pagetalk-comment {
  border: 1px solid #eee;
  padding: 1rem;
  margin: 1rem 0;
}
```

### 3. Server Setup

1. Install Dune:
```bash
curl -fsSL https://get.dune.build/install | sh
```

2. Build the project:
```bash
dune pkg lock && dune build
```

3. Run the server:
```bash
dune exec pagetalk
```

### 4. Accessing the Admin Dashboard

1. Visit `http://your-server:3000/admin`
2. Log in with your configured credentials
3. You can now:
   - View all comments
   - Moderate pending comments
   - Mark comments as spam

### 5. Security Considerations

1. Configure HTTPS for production use
2. Change the default admin password
3. Set up proper CORS headers for your domain
4. Consider rate limiting for comment submission
5. Set up proper backup for the comment database


## API Documentation

### Client API

TODO

### Server API Endpoints

TODO
