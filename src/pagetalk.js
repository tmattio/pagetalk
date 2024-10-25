// PageTalk Client Library
class PageTalk {
  constructor(config = {}) {
    this.serverUrl = config.serverUrl || 'http://localhost:3000';
    this.containerId = config.containerId || 'pagetalk-comments';
    this.container = null;
    this.comments = [];
  }

  // Initialize the comment section
  async init() {
    // Create container if it doesn't exist
    this.container = document.getElementById(this.containerId);
    if (!this.container) {
      this.container = document.createElement('div');
      this.container.id = this.containerId;
      document.body.appendChild(this.container);
    }

    // Load comments
    await this.loadComments();

    // Render initial UI
    this.render();
  }

  // Load comments from server
  async loadComments() {
    try {
      const response = await fetch(
        `${this.serverUrl}/api/comments?pageUrl=${encodeURIComponent(window.location.href)}`
      );
      const data = await response.json();
      this.comments = data.comments;
    } catch (error) {
      console.error('Failed to load comments:', error);
    }
  }

  // Post a comment to the server
  async postComment(commentData) {
    try {
      const response = await fetch(`${this.serverUrl}/api/comments`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          pageUrl: window.location.href,
          ...commentData
        }),
      });

      if (!response.ok) {
        throw new Error('Failed to post comment');
      }

      await this.loadComments();
      this.render();
    } catch (error) {
      console.error('Error posting comment:', error);
    }
  }

  // Render the main comment form
  renderCommentForm() {
    return `
    <div class="pagetalk-comment-form">
      <input 
        type="text" 
        class="pagetalk-input" 
        id="pagetalk-author-input"
        name="author"
        placeholder="Name (required)"
      />
      <input 
        type="email" 
        class="pagetalk-input" 
        id="pagetalk-email-input"
        name="email"
        autocomplete="email"
        placeholder="Email (optional)"
      />
      <input 
        type="url" 
        class="pagetalk-input" 
        id="pagetalk-website-input"
        name="website"
        placeholder="Website (optional)"
      />
      <textarea 
        class="pagetalk-textarea" 
        placeholder="Write a comment..."
        id="pagetalk-comment-input"
        name="content"
      ></textarea>
      <button class="pagetalk-button" onclick="pageTalk.submitComment()">
        Post Comment
      </button>
    </div>
  `;
  }

  // Render a reply form for a specific comment
  renderReplyForm(commentId) {
    return `
    <div id="reply-form-${commentId}" class="pagetalk-reply-form" style="display: none;">
      <input 
        type="text" 
        class="pagetalk-input" 
        id="pagetalk-reply-author-${commentId}"
        name="author"
        placeholder="Name (required)"
      />
      <input 
        type="email" 
        class="pagetalk-input" 
        id="pagetalk-reply-email-${commentId}"
        name="email"
        placeholder="Email (optional)"
      />
      <input 
        type="url" 
        class="pagetalk-input" 
        id="pagetalk-reply-website-${commentId}"
        name="website"
        placeholder="Website (optional)"
      />
      <textarea 
        class="pagetalk-textarea" 
        placeholder="Write a reply..."
        id="pagetalk-reply-content-${commentId}"
        name="content"
      ></textarea>
      <button class="pagetalk-button" onclick="pageTalk.submitReply('${commentId}')">
        Submit Reply
      </button>
    </div>
  `;
  }

  // Render a single comment
  renderComment(comment, level = 0) {
    const date = new Date(comment.timestamp * 1000);
    const authorHtml = comment.website
      ? `<a href="${this.escapeHtml(comment.website)}" rel="nofollow" target="_blank">${this.escapeHtml(comment.author)}</a>`
      : this.escapeHtml(comment.author);

    return `
      <div class="pagetalk-comment" data-comment-id="${comment.id}">
        <div class="pagetalk-comment-header">
          <span class="pagetalk-author">${authorHtml}</span>
          <span class="pagetalk-timestamp">${date.toLocaleDateString()}</span>
        </div>
        <div class="pagetalk-content">
          ${this.escapeHtml(comment.content)}
        </div>
        <button class="pagetalk-reply-button" onclick="pageTalk.showReplyForm('${comment.id}')">
          Reply
        </button>
        ${this.renderReplyForm(comment.id)}
        ${comment.replies ? `
          <div class="pagetalk-replies">
            ${comment.replies.map(reply => this.renderComment(reply, level + 1)).join('')}
          </div>
        ` : ''}
      </div>
    `;
  }

  // Render the entire comment section
  render() {
    const html = `
      <div class="pagetalk-container">
        ${this.renderCommentForm()}
        <div class="pagetalk-comments">
          ${this.comments.map(comment => this.renderComment(comment)).join('')}
        </div>
      </div>
    `;
    this.container.innerHTML = html;
  }

  // Submit a new comment
  async submitComment() {
    const content = document.getElementById('pagetalk-comment-input').value.trim();
    const author = document.getElementById('pagetalk-author-input').value.trim();
    const email = document.getElementById('pagetalk-email-input').value.trim();
    const website = document.getElementById('pagetalk-website-input').value.trim();

    if (!content) {
      alert('Please write a comment');
      return;
    }
    if (!author) {
      alert('Please provide your name');
      return;
    }

    await this.postComment({
      content,
      author,
      email: email || null,
      website: website || null
    });

    // Clear form
    document.getElementById('pagetalk-comment-input').value = '';
    document.getElementById('pagetalk-author-input').value = '';
    document.getElementById('pagetalk-email-input').value = '';
    document.getElementById('pagetalk-website-input').value = '';
  }

  // Show reply form for a comment
  showReplyForm(commentId) {
    const replyForm = document.getElementById(`reply-form-${commentId}`);
    if (replyForm) {
      replyForm.style.display = replyForm.style.display === 'none' ? 'block' : 'none';
    }
  }

  // Submit a reply to a comment
  async submitReply(parentId) {
    const replyForm = document.getElementById(`reply-form-${parentId}`);
    const content = replyForm.querySelector('textarea').value.trim();
    const author = replyForm.querySelector('input[type="text"]').value.trim();
    const email = replyForm.querySelector('input[type="email"]').value.trim();
    const website = replyForm.querySelector('input[type="url"]').value.trim();

    if (!content) {
      alert('Please write a reply');
      return;
    }
    if (!author) {
      alert('Please provide your name');
      return;
    }

    await this.postComment({
      content,
      author,
      email: email || null,
      website: website || null,
      parentId
    });

    // Clear and hide form
    replyForm.style.display = 'none';
    replyForm.querySelector('textarea').value = '';
    replyForm.querySelector('input[type="text"]').value = '';
    replyForm.querySelector('input[type="email"]').value = '';
    replyForm.querySelector('input[type="url"]').value = '';
  }

  // Helper method to escape HTML
  escapeHtml(unsafe) {
    return unsafe
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;")
      .replace(/'/g, "&#039;");
  }
}

// Export for both module and script tag usage
if (typeof module !== 'undefined' && module.exports) {
  module.exports = PageTalk;
} else {
  window.PageTalk = PageTalk;
}