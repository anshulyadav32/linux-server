# GitHub Pages Setup Instructions

Follow these steps to publish your server setup scripts website using GitHub Pages:

## 1. Create a GitHub Repository

First, create a new repository on GitHub:

1. Go to [GitHub](https://github.com) and sign in
2. Click the "+" icon in the top right and select "New repository"
3. Name your repository (e.g., "server-setup-scripts")
4. Make it public if you want the pages to be publicly visible
5. Click "Create repository"

## 2. Connect Your Local Repository to GitHub

Replace `YOUR_USERNAME` with your GitHub username and `REPO_NAME` with your repository name:

```bash
# Add the remote GitHub repository
git remote add origin https://github.com/YOUR_USERNAME/REPO_NAME.git

# Push your code to GitHub
git push -u origin main
```

## 3. Enable GitHub Pages

1. Go to your repository on GitHub
2. Click "Settings"
3. Scroll down to the "GitHub Pages" section
4. Under "Source", select "GitHub Actions"

## 4. Wait for Deployment

1. Go to the "Actions" tab in your repository
2. You should see the "Deploy GitHub Pages" workflow running
3. Wait for it to complete (this usually takes a minute or two)

## 5. View Your Website

Once the deployment is complete, your website will be available at:

```
https://YOUR_USERNAME.github.io/REPO_NAME/
```

## Making Updates

Any time you push changes to your main branch, GitHub Actions will automatically rebuild and deploy your website.

## Customizing Your Site

- Edit `index.html` to change the main page content
- Modify `assets/css/style.css` to adjust the styling
- Update `_config.yml` to change Jekyll theme settings
