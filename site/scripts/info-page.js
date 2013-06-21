var InfoPage = function() {
  Page.call(this, 'info');
};

InfoPage.prototype = new Page();

InfoPage.prototype._didLoad = function() {
  var backButton = this.element.querySelector('.back-button');
  backButton.onclick = this._onClickBack.bind(this);
};

InfoPage.prototype._onClickBack = function(event) {
  if (event.metaKey || event.ctrlKey) {
    return;
  }

  event.preventDefault();
  window.history.back();
};