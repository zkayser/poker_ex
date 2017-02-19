import $ from 'jquery';

export default class Pagination {
  constructor(opts) {
    this.default = opts.default || 1;
    this.defaultLinks = opts.defaultLinks || [$("#page-1"), $("#page-2"), $("#page-3"), $("#page-4"), $("#page-5")];
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
    this.appendPageNumHeadings(payload);
    this.addActive(payload);
    this.removeDisabledClass();
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
  
  removeDisabledClass() {
    this.pageBack.removeClass('disabled');
    this.pageAhead.removeClass('disabled');
  }
  
  disableButtonIfNeeded(payload) {
    console.log("disableBtn? - payload.current_page: ", payload);
    console.log("isFirstPage?: ", this.isFirstPage(payload));
    if (this.isFirstPage(payload)) {
      this.pageBack.addClass('disabled');
    } else if (this.isLastPage(payload)) {
      this.pageAhead.addClass('disabled');
    }
  }
  
  removeActive() {
    $(".active-page").removeClass('active-page');
  }
  
  addActive(payload) {
    $(`#page-${payload.current_page}`).addClass('active-page');
  }
  
  changePageNumHeadings(payload) {
    return payload.current_page > 5 && payload.current_page < payload.total;
  }
  
  makeRangeForNumber(payload) {
    let number = payload.current_page;
    let remFive = number % 5;
    let start = (number - remFive) + 1;
    let pageNums = [];
    while (start < payload.total || pageNums.length < 5) {
      console.log("start: ", start);
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
  
  appendPageNumHeadings(payload) {
    if (this.changePageNumHeadings(payload)) {
      let range = this.makeRangeForNumber(payload);
      let pageNums = this.buildPageNumListElems(range);
      $(".page-numbers").empty();
      for (let i = 0; i < pageNums.length; i++) {
        $(".page-numbers").append(pageNums[i]);
        pageNums[i].off('click');
        pageNums[i].on('click', (e) => {
          let id = pageNums[i].attr('id');
          id = id.split("-")[1];
          this.channel.push("new_page", {get: id});
        });
      }
    }
  }
}