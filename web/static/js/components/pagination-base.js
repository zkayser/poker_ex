import $ from 'jquery';

export default class PaginationBase {
  
  constructor(opts) {
    this.currentPage = opts.currentPage || 1;
    this.lowPage = 1;
    this.activeListEl = opts.activeListEl || $("#page-1");
    opts.totalPages < 5 ? this.highPage = opts.totalPages : this.highPage = 5;
    this.activeClass = opts.activeClass || 'active-page';
    this.newLinksOn = opts.newLinksOn || 5;
    this.totalPages = opts.totalPages || 1;
    this.pageBack = opts.pageBack || $("#page-back");
    this.pageAhead = opts.pageAhead || $("#page-ahead");
    this.liTextColor = opts.liTextColor || 'teal-text';
  }
  
  update(newPage, component) {
    let page = parseInt(newPage, 10);
    this.currentPage = page;
    let range = this.makeRange();
    let listElems = this.buildPageNumListElems(range);
    this.appendPageNumHeadings(listElems);
    this.removeActiveAndAddTo($(`#page-${newPage}`));
    this.disableButtonIfNeeded(this.currentPage);
    // Requires every component to respond to setEventListeners
    component.setEventListeners();
  }
  
  getPageElements() {
    let elems = [];
    let num = this.lowPage;
    if (num == this.highPage) {
      elems.push($(`#page-${num}`));
    } else {
      while (num <= this.highPage) {
        elems.push($(`#page-${num}`));
        num++;
      }
    }
    return elems;
  }
  
  // Abstract methods
  setEventListeners() {
    throw new this.NotImplementedException('setEventListeners');
  }
  
  // Private
  
  removeActiveAndAddTo(target) {
    this.activeListEl.removeClass(this.activeClass);
    this.activeListEl = target;
    this.activeListEl.addClass(this.activeClass);
  }
  
  isFirstPage(page) {
    return page == 1;
  }
  
  isLastPage(page) {
    return page == this.totalPages;
  }
  
  disableButtonIfNeeded(page) {
    if (this.isFirstPage(page)) {
      this.pageBack.addClass('disabled');
      this.pageBack.off('click');
    } else if (this.isLastPage(page)) {
      this.pageAhead.addClass('disabled');
      this.pageAhead.off('click');
    }
  }
  
  removeDisabledClass(pageBackHandler, pageAheadHandler) {
    if (this.pageBack.hasClass('disabled')) {
      this.pageBack.removeClass('disabled');
      this.pageBack.off('click');
      this.pageBack.on('click', pageBackHandler(this.currentPage));
    }
    if (this.pageAhead.hasClass('disabled')) {
      this.pageAhead.removeClass('disabled');
      this.pageAhead.on('click', pageAheadHandler(this.currentPage));
    }
  }
  
  makeRange() {
    let number = this.currentPage;
    let rem = number % this.newLinksOn;
    let start;
    if (rem == 0) {
      start = (number - (this.newLinksOn - 1));
    } else {
      start = (number - rem) + 1;
    }

    let pageNums = [];
    while (start <= this.totalPages && pageNums.length < this.newLinksOn) {
      pageNums.push(start);
      start++;
    }
    this.lowPage = pageNums[0];
    this.highPage = pageNums[pageNums.length - 1];
    return pageNums;
  }
  
  buildPageNumListElems(numbers) {
    let listElems = [];
    for (let i = 0; i < numbers.length; i++) {
      let textColor;
      (i + 1) == this.currentPage ? textColor = 'white-text' : textColor = this.liTextColor;
      listElems.push($(`<li class="page-btn" id="page-${numbers[i]}"><a class="${textColor}" href="#!">${numbers[i]}</a></li>`));
    }
    return listElems;
  }
  
  appendPageNumHeadings(listElems) {
    $(".page-numbers").empty();
    for (let i = 0; i < listElems.length; i++) {
      $(".page-numbers").append(listElems[i]);
    }
  }
  
  NotImplementedException(method) {
    return function NotImplementedException(method) {
      this.message = `${method} has not been implemented.`;
    };
  }
}