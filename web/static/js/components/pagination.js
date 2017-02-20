import $ from 'jquery';

export default class Pagination {
  constructor(opts) {
    this.default = opts.default || 1;
    this.defaultLinks = opts.defaultLinks || [$("#page-1"), $("#page-2"), $("#page-3"), $("#page-4"), $("#page-5")];
    this.showingPages = opts.showingPages || [1, 2, 3, 4, 5]; 
    this.pageBack = opts.pageBack || $("#page-back");
    this.pageAhead = opts.pageAhead || $("#page-ahead");
    this.newLinksOn = opts.newLinksOn || 5;
    this.currentPage = opts.currentPage || $(".pagination").data("currentPage");
    this.channel = opts.channel;
    this.appendTarget = opts.appendTarget || $("#participating-table-body");
  }
  
  init() {
    this.pageBack.on('click', (e) => {
      if (!(e.currentTarget.className == 'disabled')) {
        this.channel.push("new_page", {current: this.currentPage, get: "back"});
      }
    });
    this.pageAhead.on('click', (e) => {
      if (!(e.currentTarget.className == 'disabled')) {
        this.channel.push("new_page", {current: this.currentPage, get: "ahead"});
      }
    });
    this.defaultLinks.forEach((el) => {
      el.on('click', (e) => {
        let id = el.attr('id');
        id = id.split("-")[1];
        this.channel.push("new_page", {get: id});
      });
    });
  }
  
  update(payload) {
    this.removeActive();
    this.changePageNumHeadings(payload);
    this.addActive(payload);
    this.removeDisabledClass(payload);
    this.disableButtonIfNeeded(payload);
    let entries = [];
    payload.entries.forEach((entry) => {
      entries.push(this.buildEntry(entry));
    });
    this.currentPage = payload.current_page;
    this.totalPages = payload.total_pages;
    this.appendTarget.empty();
    for (let i = 0; i < entries.length; i++) {
      this.appendTarget.append(entries[i]);
    }
  }
  
  // private
  buildEntry(entry) {
    return $(`
      <tr>
        <td>${entry.title}</td>
        <td>${entry.participants}</td>
        <td><a href="${entry.link}" class="btn-floating white-text green waves-effect" type="button">Go</button></td>
      </tr>
    `);
  }
  
  isFirstPage(payload) {
    let bool = payload.current_page == 1 ? true : false;
    return bool;
  }
  
  isLastPage(payload) {
    let bool = payload.current_page == payload.total ? true : false;
    return bool;
  }
  
  removeDisabledClass(payload) {
    if (this.pageBack.hasClass('disabled')) {
      this.pageBack.removeClass('disabled');
      this.pageBack.off('click');
      this.pageBack.on('click', (e) => {
        this.channel.push("new_page", {current: this.currentPage, get: "back"});
      });
    }
    if (this.pageAhead.hasClass('disabled')) {
      this.pageAhead.removeClass('disabled');
      this.pageAhead.on('click', (e) => {
        this.channel.push('new_page', {current: this.currentPage, get: "ahead"});
      });
    }
  }
  
  disableButtonIfNeeded(payload) {
    if (this.isFirstPage(payload)) {
      this.pageBack.addClass('disabled');
      this.pageBack.off('click');
    } else if (this.isLastPage(payload)) {
      this.pageAhead.addClass('disabled');
      this.pageAhead.off('click');
    }
  }
  
  removeActive() {
    $(".active-page").removeClass('active-page');
  }
  
  addActive(payload) {
    $(`#page-${payload.current_page}`).addClass('active-page');
  }
  
  changePageNumHeadings(payload) {
    if (this.showingPages.includes(payload.current_page)) {
      return;
    } else {
      this.showingPages = this.makeRangeForNumber(payload);
      let listElems = this.buildPageNumListElems(this.showingPages);
      this.appendPageNumHeadings(listElems);
    }
  }
  
  makeRangeForNumber(payload) {
    let number = payload.current_page;
    let remFive = number % 5;
    let start;
    if (remFive == 0) {
      start = (number - 4);
    } else {
      start = (number - remFive) + 1;
    }
    let pageNums = [];
    while (start <= payload.total && pageNums.length < 5) {
      pageNums.push(start);
      start++;
    }
    return pageNums;
  }
  
  buildPageNumListElems(numbers) {
    let listElems = [];
    for (let i = 0; i < numbers.length; i++) {
      listElems.push($(`<li class="page-btn" id="page-${numbers[i]}"><a class="white-text" href="#!">${numbers[i]}</a></li>`));
    }
    return listElems;
  }
  
  appendPageNumHeadings(listElems) {
    $(".page-numbers").empty();
    for (let i = 0; i < listElems.length; i++) {
      $(".page-numbers").append(listElems[i]);
      listElems[i].off('click');
      listElems[i].on('click', (e) => {
        let id = listElems[i].attr('id');
        id = id.split("-")[1];
        this.channel.push("new_page", {get: id});
      });
    }
  }
}